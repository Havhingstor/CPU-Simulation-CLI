//
//  Utilities.swift
//  CPU-Simulation-CLI
//
//  Created by Paul on 22.12.21.
//

import Foundation
import CPU_Simulation_Lib
import CPU_Simulation_Utilities

func getBusses(cpu: CPU, assemblingResults: AssemblingResults) -> String {
    var addressString = "Empty"
    var dataString = "Empty"
    
    if let addressBus = cpu.addressBus, let dataBus = cpu.dataBus {
        addressString = toLongHexString(addressBus)
        
        let valueType = assemblingResults.memoryValues[addressBus] ?? AssemblingResults.AddressAddressValue()
        
        dataString = valueType.transformOnlyNumber(value: dataBus)
    }
    
    var result =    "Address-Bus:\t\(addressString)\n"
    result +=       "Data-Bus:   \t\(dataString)\n\n"
    
    
    return result
}

func getMemoryRepresentation(cpu: CPU, mem: Memory, results: AssemblingResults) -> String {
    var result = "Memory:\n"
    
    result += getBusses(cpu: cpu, assemblingResults: results)
    
    let usedLines = calculateUsedLines(memory: mem)
    
    if usedLines.isEmpty {
        result += "No Values"
        return result
    }
    
    let table = createTable(usedLines, assemblingResults: results, memory: mem)
    
    result += getTable(values: table, header: true, additionalDistance: 2, unifiedDistance: true)
    
    return result
}


private func getStartOfTable() -> [[String]] {
    return [["","0","1","2","3","4","5","6","7","8","9","A","B","C","D","E","F"]]
}

private func calculateUsedLines(memory: Memory) -> [UInt16] {
    var usedLines: [UInt16] = []
    
    for i in 0 ... UInt16(0xffff) {
        let val = i & 0xFFF0
        if memory.read(address: i) != 0 && !usedLines.contains(val) {
            usedLines.append(val)
        }
    }
    
    return usedLines
}

private func createFirstAddressFromLineNr(_ i: UInt16) -> UInt16 {
    return i << 4
}

private func testIfLineWasUsed(usedLines: [UInt16], lineNr: UInt16) -> Bool {
    return usedLines.contains(lineNr)
}

private func createStartOfNewLine(_ firstAddressNr: UInt16) -> [String] {
    return [toHexString(firstAddressNr)]
}

private func calculateAddressFromLineAndNr(lineNr: UInt16, address: UInt16) -> UInt16 {
    return lineNr | address
}

private func getStringOfAddress(memory: Memory, lineNr: UInt16, address: UInt16, assemblingResults: AssemblingResults) -> String {
    let realAddress = calculateAddressFromLineAndNr(lineNr: lineNr, address: address)
    let value = memory.read(address: realAddress)
    
    let valueType = assemblingResults.memoryValues[realAddress] ?? AssemblingResults.AddressAddressValue()
    
    return valueType.transform(value: value)
}
fileprivate func addAddressToLine(line: inout [String], lineNr: UInt16, address: UInt16, assemblingResults: AssemblingResults, memory: Memory) {
    line.append(getStringOfAddress(memory: memory, lineNr: lineNr, address: address, assemblingResults: assemblingResults))
}

fileprivate func handleUsageOfLastLineInResultString(lastLineUsed:  Bool, result: inout [[String]]) {
    if lastLineUsed {
        let addition: [String] = Array(repeating: "...", count: 17)
        result.append(addition)
    }
}

fileprivate func appendUsedLine(firstAddressNr: UInt16, result: inout [[String]], assemblingResults: AssemblingResults, memory: Memory) {
    var newLine = createStartOfNewLine(firstAddressNr)
    
    for j in 0 ... UInt16(0xf) {
        addAddressToLine(line: &newLine, lineNr: firstAddressNr, address: j, assemblingResults: assemblingResults, memory: memory)
    }
    
    result.append(newLine)
}

private func createTable(_ usedLines: [UInt16], assemblingResults: AssemblingResults, memory: Memory) -> [[String]] {
    var result = getStartOfTable()
    var lastLineUsed = true
    
    for i in 0 ... UInt16(0xfff) {
        let firstAddressNr = createFirstAddressFromLineNr(i)
        
        if testIfLineWasUsed(usedLines: usedLines, lineNr: firstAddressNr) {
            appendUsedLine(firstAddressNr: firstAddressNr, result: &result, assemblingResults: assemblingResults, memory: memory)
            lastLineUsed = true
        } else {
            handleUsageOfLastLineInResultString(lastLineUsed: lastLineUsed, result: &result)
            lastLineUsed = false
        }
    }
    
    return result
}

