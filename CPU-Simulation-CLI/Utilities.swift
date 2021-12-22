//
//  Utilities.swift
//  CPU-Simulation-CLI
//
//  Created by Paul on 22.12.21.
//

import Foundation
import CPU_Simulation_Lib

func getMemoryRepresentation(mem: Memory, results: ParseResults) -> String {
    var result = "Memory:\n"
    var usedLines: [UInt16] = []
    var lastLineUsed = true
    
    for i in 0 ... "FFFF".uHex {
        let val = i & 0xFFF0
        if mem.read(address: i) != 0 && !usedLines.contains(val) {
            usedLines.append(val)
        }
    }
    
    if usedLines.isEmpty {
        result += "No Values"
        return result
    }
    
    var table: [[String]] = [["","0","1","2","3","4","5","6","7","8","9","A","B","C","D","E","F"]]
    
    for i in 0 ... "FFF".uHex {
        let nr = i << 4
        if usedLines.contains(nr) {
            var addition = [hex(nr, long: false)]
            for j in 0 ... "F".uHex {
                let address = nr | j
                let val = mem.read(address: address)
                let output: String
                if let op = results.operators[address] {
                    output = op.string
                } else if results.addresses.contains(address) {
                    output = "0x" + hex(val)
                } else {
                    output = String(val)
                }
                addition.append(output)
            }
            table.append(addition)
            lastLineUsed = true
        } else {
            if lastLineUsed {
                let addition: [String] = Array(repeating: "...", count: 17)
                table.append(addition)
                lastLineUsed = false
            }
        }
    }
    
    result += getTable(values: table, header: true, additionalDistance: 2, unifiedDistance: true)
    
    return result
}
