#include <ArduinoBLE.h>
#include <Arduino_HS300x.h>
#include <mbed.h>  // For low-power sleep modes

// ============================================================================
// BLE SERVICE AND CHARACTERISTIC DEFINITIONS
// Custom 128-bit UUIDs (Bluetooth SIG compliant)
// ============================================================================

BLEService environmentalService("5971e8f1-bc4d-4a5f-a6fd-3591131a98c6");
BLEFloatCharacteristic temperatureChar("78b20af1-e597-40c1-a69c-304205b7e099", BLERead | BLENotify);
BLEFloatCharacteristic humidityChar("0ba15aa1-a805-4205-bc82-af2e4a9364c5", BLERead | BLENotify);
// Battery Mode Control Characteristic (Read/Write)
BLEByteCharacteristic batteryModeChar("a1b2c3d4-e5f6-4789-a012-3456789abcde", BLERead | BLEWrite);

// ============================================================================
// POWER MODE CONFIGURATION
// ============================================================================

enum PowerMode {
    MODE_NORMAL,        // Full features, 1s sampling, LEDs on
    MODE_BATTERY        // Low power, 60s sampling, LEDs off, reduced BLE
};

PowerMode currentPowerMode = MODE_NORMAL;

// Physical switch pin (optional - connect switch between pin and GND)
const int MODE_SWITCH_PIN = 2;  // D2 - change if needed
const bool USE_PHYSICAL_SWITCH = false;  // Set true if you add physical switch

// ============================================================================
// CONFIGURATION CONSTANTS - NORMAL MODE
// ============================================================================

const char* DEVICE_NAME = "Cricket";
const unsigned long NORMAL_SAMPLE_INTERVAL = 1000;    // 1 second
const unsigned long BATTERY_SAMPLE_INTERVAL = 60000;  // 60 seconds (1 minute)
const int AVERAGE_WINDOW = 5;
const float TEMP_THRESHOLD_NORMAL = 0.5;              // 0.5°C
const float HUM_THRESHOLD_NORMAL = 0.5;               // 0.5%RH
const float TEMP_THRESHOLD_BATTERY = 1.0;             // 1.0°C (less sensitive)
const float HUM_THRESHOLD_BATTERY = 2.0;              // 2.0%RH (less sensitive)

// ============================================================================
// RGB LED CONFIGURATION (Active-LOW: LOW = ON, HIGH = OFF)
// ============================================================================

enum BLEState {
    STATE_ADVERTISING,
    STATE_CONNECTED,
    STATE_DISCONNECTED,
    STATE_DATA_TRANSFER,
    STATE_OFF  // Battery mode - all LEDs off
};

BLEState currentState = STATE_ADVERTISING;

// ============================================================================
// FUNCTION FORWARD DECLARATIONS
// ============================================================================

void setLEDState(BLEState state);
void enterBatteryMode();
void enterNormalMode();
void lowPowerDelay(unsigned long ms);

// ============================================================================
// GLOBAL VARIABLES
// ============================================================================

float tempReadings[AVERAGE_WINDOW];
float humReadings[AVERAGE_WINDOW];
int sampleIndex = 0;
int sampleCount = 0;

float lastTempSent = -999.0;
float lastHumSent = -999.0;
bool firstReading = true;

unsigned long lastSampleTime = 0;
bool isConnected = false;
bool wasConnected = false;

bool sensorInitialized = false;
bool sensorError = false;
unsigned long startTime = 0;

// ============================================================================
// SETUP FUNCTION
// ============================================================================

void setup() {
    Serial.begin(115200);
    while (!Serial) delay(10);

    startTime = millis();

    Serial.println("=== Cricket Low-Power Peripheral ===");
    Serial.println("Arduino Nano 33 BLE Sense Rev2 (nRF52840)");
    Serial.println("Service: 5971e8f1-bc4d-4a5f-a6fd-3591131a98c6");
    Serial.println("Battery Mode Support: ENABLED");
    Serial.println("========================================");

    // Initialize physical mode switch (if enabled)
    if (USE_PHYSICAL_SWITCH) {
        pinMode(MODE_SWITCH_PIN, INPUT_PULLUP);
        Serial.print("Physical switch on pin D");
        Serial.print(MODE_SWITCH_PIN);
        Serial.println(" (LOW = Battery Mode)");
    }

    // Initialize RGB LED pins
    pinMode(LEDR, OUTPUT);
    pinMode(LEDG, OUTPUT);
    pinMode(LEDB, OUTPUT);
    setLEDState(STATE_DISCONNECTED);

    // Initialize sensor
    if (!HS300x.begin()) {
        Serial.println("ERROR: Failed to initialize HS3003 sensor!");
        sensorError = true;
        sensorInitialized = false;
    } else {
        Serial.println("SUCCESS: HS300x sensor initialized");
        sensorInitialized = true;
        sensorError = false;
    }

    // Initialize BLE
    if (!BLE.begin()) {
        Serial.println("ERROR: Failed to start BLE!");
        while (1) {
            delay(1000);
        }
    }
    Serial.println("SUCCESS: BLE initialized");

    // Configure BLE
    BLE.setLocalName(DEVICE_NAME);
    environmentalService.addCharacteristic(temperatureChar);
    environmentalService.addCharacteristic(humidityChar);
    environmentalService.addCharacteristic(batteryModeChar);
    BLE.addService(environmentalService);
    BLE.setAdvertisedService(environmentalService);

    // Initialize characteristics
    temperatureChar.writeValue(0.0);
    humidityChar.writeValue(0.0);
    batteryModeChar.writeValue(0);  // 0 = Normal, 1 = Battery

    // Initialize reading arrays
    for (int i = 0; i < AVERAGE_WINDOW; i++) {
        tempReadings[i] = 0.0;
        humReadings[i] = 0.0;
    }

    // Start advertising
    BLE.advertise();
    setLEDState(STATE_ADVERTISING);

    Serial.println("Mode: NORMAL (full power)");
    Serial.println("  - Sample interval: 1 second");
    Serial.println("  - LEDs: Enabled");
    Serial.println("  - BLE: Full power");
    Serial.println();
    Serial.println("To enable Battery Mode:");
    Serial.println("  1. Use iOS/Mac app to send BLE command");
    if (USE_PHYSICAL_SWITCH) {
        Serial.print("  2. Toggle switch on pin D");
        Serial.println(MODE_SWITCH_PIN);
    }
    Serial.println("========================================");
}

// ============================================================================
// MAIN LOOP
// ============================================================================

void loop() {
    BLE.poll();

    // Check for mode change via physical switch
    if (USE_PHYSICAL_SWITCH) {
        checkPhysicalSwitch();
    }

    // Check for mode change via BLE command
    if (batteryModeChar.written()) {
        byte newMode = batteryModeChar.value();
        if (newMode == 1 && currentPowerMode == MODE_NORMAL) {
            enterBatteryMode();
        } else if (newMode == 0 && currentPowerMode == MODE_BATTERY) {
            enterNormalMode();
        }
    }

    handleConnectionStateChange();

    // Determine current sample interval based on mode
    unsigned long sampleInterval = (currentPowerMode == MODE_BATTERY)
                                    ? BATTERY_SAMPLE_INTERVAL
                                    : NORMAL_SAMPLE_INTERVAL;

    if (millis() - lastSampleTime >= sampleInterval) {
        takeSensorReading();
        lastSampleTime = millis();
    }

    // Use low-power delay in battery mode, regular delay in normal mode
    if (currentPowerMode == MODE_BATTERY) {
        lowPowerDelay(100);  // 100ms low-power sleep
    } else {
        delay(10);  // Normal 10ms delay
    }
}

// ============================================================================
// POWER MODE MANAGEMENT
// ============================================================================

void enterBatteryMode() {
    currentPowerMode = MODE_BATTERY;

    // Turn off all LEDs immediately
    setLEDState(STATE_OFF);

    // Reduce BLE advertising interval (saves power when not connected)
    // Note: This requires disconnecting and restarting advertising
    if (!isConnected) {
        BLE.stopAdvertise();
        // Longer advertising interval = less power consumption
        // Default is 100ms, we'll use implicit longer interval by advertising less
        delay(100);
        BLE.advertise();
    }

    Serial.println("========================================");
    Serial.println("BATTERY MODE ACTIVATED");
    Serial.println("  - Sample interval: 60 seconds");
    Serial.println("  - LEDs: DISABLED");
    Serial.println("  - Thresholds: Reduced sensitivity");
    Serial.println("  - Low-power sleep: ENABLED");
    Serial.println("========================================");

    // Update BLE characteristic
    batteryModeChar.writeValue(1);
}

void enterNormalMode() {
    currentPowerMode = MODE_NORMAL;

    // Re-enable LEDs
    if (isConnected) {
        setLEDState(STATE_CONNECTED);
    } else {
        setLEDState(STATE_ADVERTISING);
    }

    Serial.println("========================================");
    Serial.println("NORMAL MODE ACTIVATED");
    Serial.println("  - Sample interval: 1 second");
    Serial.println("  - LEDs: ENABLED");
    Serial.println("  - Thresholds: Full sensitivity");
    Serial.println("  - Low-power sleep: DISABLED");
    Serial.println("========================================");

    // Update BLE characteristic
    batteryModeChar.writeValue(0);
}

void checkPhysicalSwitch() {
    static bool lastSwitchState = HIGH;
    static unsigned long lastDebounceTime = 0;
    const unsigned long DEBOUNCE_DELAY = 50;

    bool reading = digitalRead(MODE_SWITCH_PIN);

    if (reading != lastSwitchState) {
        lastDebounceTime = millis();
    }

    if ((millis() - lastDebounceTime) > DEBOUNCE_DELAY) {
        // Switch is LOW (pressed/grounded) = Battery Mode
        // Switch is HIGH (released/pulled-up) = Normal Mode
        if (reading == LOW && currentPowerMode == MODE_NORMAL) {
            enterBatteryMode();
        } else if (reading == HIGH && currentPowerMode == MODE_BATTERY) {
            enterNormalMode();
        }
    }

    lastSwitchState = reading;
}

// ============================================================================
// LOW-POWER SLEEP FUNCTION
// ============================================================================

void lowPowerDelay(unsigned long ms) {
    // Use ARM Cortex-M4 sleep mode
    // This puts CPU to sleep but keeps peripherals running (BLE, timers)
    unsigned long start = millis();
    while (millis() - start < ms) {
        // __WFE() = Wait For Event (low power sleep)
        // CPU sleeps until interrupt/event wakes it
        __WFE();
    }
}

// ============================================================================
// BLE CONNECTION HANDLING
// ============================================================================

void handleConnectionStateChange() {
    isConnected = BLE.connected();

    if (isConnected && !wasConnected) {
        Serial.println("BLE CONNECTED: Central device connected");

        // Update LED only in normal mode
        if (currentPowerMode == MODE_NORMAL) {
            setLEDState(STATE_CONNECTED);
        }

        BLE.stopAdvertise();
        wasConnected = true;
        firstReading = true;
    }

    if (!isConnected && wasConnected) {
        Serial.println("BLE DISCONNECTED: Central device disconnected");
        Serial.println("Restarting advertising...");

        // Update LED only in normal mode
        if (currentPowerMode == MODE_NORMAL) {
            setLEDState(STATE_ADVERTISING);
        }

        BLE.advertise();
        wasConnected = false;
    }
}

// ============================================================================
// SENSOR READING AND PROCESSING
// ============================================================================

void takeSensorReading() {
    float temperature = 0.0;
    float humidity = 0.0;
    bool validReading = true;

    if (sensorInitialized && !sensorError) {
        temperature = HS300x.readTemperature();
        humidity = HS300x.readHumidity();

        if (isnan(temperature) || isnan(humidity) || isinf(temperature) || isinf(humidity)) {
            Serial.println("SENSOR ERROR: Invalid reading");
            validReading = false;
        }

        if (validReading && (temperature < -40.0 || temperature > 120.0 ||
                             humidity < 0.0 || humidity > 100.0)) {
            Serial.println("SENSOR ERROR: Reading out of range");
            validReading = false;
        }
    } else {
        validReading = false;
    }

    if (validReading) {
        tempReadings[sampleIndex] = temperature;
        humReadings[sampleIndex] = humidity;
        sampleIndex = (sampleIndex + 1) % AVERAGE_WINDOW;

        if (sampleCount < AVERAGE_WINDOW) {
            sampleCount++;
        }
    }

    float avgTemp = round(calculateAverage(tempReadings, sampleCount) * 10.0) / 10.0;
    float avgHum = calculateAverage(humReadings, sampleCount);

    String tempStr = String(validReading ? temperature : 0.0, 1);
    String humStr = String(validReading ? humidity : 0.0, 1);
    String avgTempStr = String(avgTemp, 1);
    String avgHumStr = String(avgHum, 1);

    Serial.print("Raw: " + tempStr + "°C, " + humStr + "% | ");
    Serial.print("Avg(" + String(sampleCount) + "): " + avgTempStr + "°C, " + avgHumStr + "%");

    // Use mode-appropriate thresholds
    float tempThreshold = (currentPowerMode == MODE_BATTERY)
                          ? TEMP_THRESHOLD_BATTERY
                          : TEMP_THRESHOLD_NORMAL;
    float humThreshold = (currentPowerMode == MODE_BATTERY)
                         ? HUM_THRESHOLD_BATTERY
                         : HUM_THRESHOLD_NORMAL;

    bool shouldSend = firstReading ||
                      abs(avgTemp - lastTempSent) >= tempThreshold ||
                      abs(avgHum - lastHumSent) >= humThreshold;

    if (shouldSend && isConnected) {
        transmitData(avgTemp, avgHum);
        Serial.println(" -> SENT");
    } else if (shouldSend && !isConnected) {
        Serial.println(" -> (not connected)");
    } else {
        Serial.println("");
    }
}

// ============================================================================
// UTILITY FUNCTIONS
// ============================================================================

float calculateAverage(float* readings, int count) {
    if (count == 0) return 0.0;

    float sum = 0.0;
    for (int i = 0; i < count; i++) {
        sum += readings[i];
    }
    return sum / count;
}

void transmitData(float temperature, float humidity) {
    if (!isConnected) {
        return;
    }

    // Flash purple during data transfer (only in normal mode)
    if (currentPowerMode == MODE_NORMAL) {
        setLEDState(STATE_DATA_TRANSFER);
    }

    temperatureChar.writeValue(temperature);
    humidityChar.writeValue(humidity);

    lastTempSent = temperature;
    lastHumSent = humidity;
    firstReading = false;

    String tempStr = String(temperature, 1);
    String humStr = String(humidity, 1);
    Serial.println("BLE TX: " + tempStr + "°C, " + humStr + "%");

    // Return to green (only in normal mode)
    if (currentPowerMode == MODE_NORMAL) {
        delay(100);
        setLEDState(STATE_CONNECTED);
    }
}

// ============================================================================
// RGB LED CONTROL
// ============================================================================

void setLEDState(BLEState state) {
    currentState = state;

    // In battery mode, always keep LEDs off
    if (currentPowerMode == MODE_BATTERY && state != STATE_OFF) {
        state = STATE_OFF;
    }

    switch (state) {
        case STATE_ADVERTISING:
            // Blue
            analogWrite(LEDR, 255);
            analogWrite(LEDG, 255);
            analogWrite(LEDB, 0);
            break;

        case STATE_CONNECTED:
            // Green
            analogWrite(LEDR, 255);
            analogWrite(LEDG, 0);
            analogWrite(LEDB, 255);
            break;

        case STATE_DISCONNECTED:
            // Red
            analogWrite(LEDR, 0);
            analogWrite(LEDG, 255);
            analogWrite(LEDB, 255);
            break;

        case STATE_DATA_TRANSFER:
            // Purple
            analogWrite(LEDR, 128);
            analogWrite(LEDG, 255);
            analogWrite(LEDB, 128);
            break;

        case STATE_OFF:
            // All LEDs off (battery mode)
            analogWrite(LEDR, 255);
            analogWrite(LEDG, 255);
            analogWrite(LEDB, 255);
            break;
    }
}
