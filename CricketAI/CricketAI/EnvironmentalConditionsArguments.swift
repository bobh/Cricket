//
//  EnvironmentalConditionsArguments.swift
//  CricketAI
//

import FoundationModels

@Generable(description: "The reason current local environmental conditions are needed.")
nonisolated struct EnvironmentalConditionsArguments {
    @Guide(description: "Briefly describe which part of the user's request needs current local conditions.")
    let reason: String
}
