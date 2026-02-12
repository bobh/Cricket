#include <ArduinoBLE.h>
#include <Arduino_HS300x.h>

// ============================================================================
// BLE SERVICE AND CHARACTERISTIC DEFINITIONS
// Custom 128-bit UUIDs (Bluetooth SIG compliant - not using reserved 16-bit UUIDs)
// ============================================================================

BLEService environmentalService("5971e8f1-bc4d-4a5f-a6fd-3591131a98c6");
BLEFloatCharacteristic temperatureChar("78b20af1-e597-40c1-a69c-304205b7e099", BLERead | BLENotify);
BLEFloatCharacteristic humidityChar("0ba15aa1-a805-4205-bc82-af2e4a9364c5", BLERead | BLENotify);

// ============================================================================
// CONFIGURATION CONSTANTS (per PRD)
// ============================================================================

const char* DEVICE_NAME = "Nano33BLE_Sensor";
const unsigned long SAMPLE_INTERVAL = 1000;       // 1000ms (1 Hz sampling)
const int AVERAGE_WINDOW = 5;                     // 5 samples (5 seconds)
const float TEMP_THRESHOLD = 0.5;                 // 0.5°C change threshold
const float HUM_THRESHOLD = 0.5;                  // 0.5%RH change threshold

// ============================================================================
// RGB LED CONFIGURATION (Active-LOW: LOW = ON, HIGH = OFF)
// ============================================================================
// Built-in RGB LED pins on Arduino Nano 33 BLE Rev 2
// LEDR = pin 22 (red)
// LEDG = pin 23 (green)
// LEDB = pin 24 (blue)

enum BLEState {
    STATE_ADVERTISING,      // Blue:    R=HIGH, G=HIGH, B=LOW
    STATE_CONNECTED,        // Green:   R=HIGH, G=LOW,  B=HIGH
    STATE_DISCONNECTED,     // Red:     R=LOW,  G=HIGH, B=HIGH
    STATE_DATA_TRANSFER     // Purple:  R=128,  G=255,  B=128 (via analogWrite)
};

BLEState currentState = STATE_ADVERTISING;

// ============================================================================
// FUNCTION FORWARD DECLARATIONS
// ============================================================================

void setLEDState(BLEState state);

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

    // Initialize RGB LED pins (active-low)
    pinMode(LEDR, OUTPUT);
    pinMode(LEDG, OUTPUT);
    pinMode(LEDB, OUTPUT);
    setLEDState(STATE_DISCONNECTED);  // Start with red until BLE initializes

    Serial.println("=== Demetor_Peripheral_1 - BLE Environmental Sensor ===");
    Serial.println("Arduino Nano 33 BLE Sense Rev2 (nRF52840)");
    Serial.println("Custom 128-bit UUIDs (Bluetooth SIG compliant)");
    Serial.println("Service: 5971e8f1-bc4d-4a5f-a6fd-3591131a98c6");
    Serial.println("Temperature: 78b20af1-e597-40c1-a69c-304205b7e099 (°C)");
    Serial.println("Humidity: 0ba15aa1-a805-4205-bc82-af2e4a9364c5 (%RH)");
    Serial.println("========================================================");

    if (!HS300x.begin()) {
        Serial.println("ERROR: Failed to initialize HS3003 sensor via Arduino_HS300x library!");
        Serial.println("BLE services will remain available but will show 0.0 values");
        sensorError = true;
        sensorInitialized = false;
    } else {
        Serial.println("SUCCESS: HS300x sensor initialized via Arduino_HS300x library");
        sensorInitialized = true;
        sensorError = false;
    }

    if (!BLE.begin()) {
        Serial.println("ERROR: Failed to start BLE!");
        Serial.println("System halted - BLE required for operation");
        while (1) {
            delay(1000);
        }
    }
    Serial.println("SUCCESS: BLE initialized");

    BLE.setLocalName(DEVICE_NAME);
    environmentalService.addCharacteristic(temperatureChar);
    environmentalService.addCharacteristic(humidityChar);
    BLE.addService(environmentalService);
    BLE.setAdvertisedService(environmentalService);

    temperatureChar.writeValue(0.0);
    humidityChar.writeValue(0.0);

    for (int i = 0; i < AVERAGE_WINDOW; i++) {
        tempReadings[i] = 0.0;
        humReadings[i] = 0.0;
    }

    BLE.advertise();
    setLEDState(STATE_ADVERTISING);  // Blue LED when advertising
    Serial.println("SUCCESS: BLE advertising as '" + String(DEVICE_NAME) + "'");
    Serial.println("Waiting for connections...");
    Serial.println("==========================================");
}

// ============================================================================
// MAIN LOOP
// ============================================================================

void loop() {
    BLE.poll();
    handleConnectionStateChange();

    if (millis() - lastSampleTime >= SAMPLE_INTERVAL) {
        takeSensorReading();
        lastSampleTime = millis();
    }

    delay(10);
}

// ============================================================================
// BLE CONNECTION HANDLING
// ============================================================================

void handleConnectionStateChange() {
    isConnected = BLE.connected();

    if (isConnected && !wasConnected) {
        Serial.println("BLE CONNECTED: Central device connected");
        setLEDState(STATE_CONNECTED);  // Green LED when connected
        BLE.stopAdvertise();
        wasConnected = true;
        firstReading = true;
    }

    if (!isConnected && wasConnected) {
        Serial.println("BLE DISCONNECTED: Central device disconnected");
        Serial.println("Restarting advertising...");
        setLEDState(STATE_ADVERTISING);  // Blue LED when advertising again
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
        temperature = HS300x.readTemperature();  // Celsius
        humidity = HS300x.readHumidity();

        if (isnan(temperature) || isnan(humidity) || isinf(temperature) || isinf(humidity)) {
            Serial.println("SENSOR ERROR: Invalid reading - retaining last valid values");
            validReading = false;
        }

        // Range validation in Celsius (-40°C to 120°C)
        if (validReading && (temperature < -40.0 || temperature > 120.0 ||
                             humidity < 0.0 || humidity > 100.0)) {
            Serial.println("SENSOR ERROR: Reading out of range - retaining last valid values");
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

    bool shouldSend = firstReading ||
                      abs(avgTemp - lastTempSent) >= TEMP_THRESHOLD ||
                      abs(avgHum - lastHumSent) >= HUM_THRESHOLD;

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

    // Flash purple during data transfer
    setLEDState(STATE_DATA_TRANSFER);

    temperatureChar.writeValue(temperature);  // Celsius
    humidityChar.writeValue(humidity);

    lastTempSent = temperature;
    lastHumSent = humidity;
    firstReading = false;

    String tempStr = String(temperature, 1);
    String humStr = String(humidity, 1);
    Serial.println("BLE TX: " + tempStr + "°C, " + humStr + "%");

    // Return to green (connected state) after brief flash
    delay(100);  // 100ms purple flash
    setLEDState(STATE_CONNECTED);
}

// ============================================================================
// RGB LED CONTROL
// ============================================================================
// Pins are active-LOW: LOW turns LED on, HIGH turns it off
// For purple (mixed color), use analogWrite with complementary values

void setLEDState(BLEState state) {
    currentState = state;

    switch (state) {
        case STATE_ADVERTISING:
            // Blue: R=HIGH, G=HIGH, B=LOW
            // Use analogWrite with full values to override any previous analogWrite
            analogWrite(LEDR, 255);  // Red off
            analogWrite(LEDG, 255);  // Green off
            analogWrite(LEDB, 0);    // Blue full on
            break;

        case STATE_CONNECTED:
            // Green: R=HIGH, G=LOW, B=HIGH
            analogWrite(LEDR, 255);  // Red off
            analogWrite(LEDG, 0);    // Green full on
            analogWrite(LEDB, 255);  // Blue off
            break;

        case STATE_DISCONNECTED:
            // Red: R=LOW, G=HIGH, B=HIGH
            analogWrite(LEDR, 0);    // Red full on
            analogWrite(LEDG, 255);  // Green off
            analogWrite(LEDB, 255);  // Blue off
            break;

        case STATE_DATA_TRANSFER:
            // Purple: R=128, G=255, B=128
            // Active-LOW: lower value = brighter (0=full on, 255=off)
            analogWrite(LEDR, 128);   // Half red (on)
            analogWrite(LEDG, 255);   // Green off
            analogWrite(LEDB, 128);   // Half blue (on)
            break;
    }
}
