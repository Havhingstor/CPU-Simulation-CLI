//
//  main.swift
//  CPU-Simulation-CLI
//
//  Created by Paul on 20.12.21.
//

import Foundation
import CPU_Simulation_Lib
import CPU_Simulation_Utilities
import CloudKit

var executionCycles = UInt(0)

try main()

func main() throws {
    var args = CommandLine.arguments
    
    let parsedArgs = parseCLIArgs(args: &args)
    
    let s = parsedArgs.startingPoint ?? 0
    
    if args.count < 2 {
        print("No file is specified!\n")
        print("Specify the location of a assembler-file!\n")
        print("You can also specify the starting point in memory with the '-s'-flag and a decimal\nor hexadecimal number, which is positive and smaller than 65536 or 0x10000.\n")
        print("If the cpu should directly execute the code until the first HOLD-Instruction, use the '-r'-flag")
        return
    }
    
    let fm = FileManager.default
    
    if args[1] == "-h" {
        print("Specify the location of a assembler-file!\n")
        print("You can also specify the starting point in memory with the '-s'-flag and a decimal\nor hexadecimal number, which is positive and smaller than 65536 or 0x10000.\n")
        print("If the cpu should directly execute the code until the first HOLD-Instruction, use the '-r'-flag")
        return
    } else if args[1] == "-v" {
        let version = "2.0"
        let date = "16.3.2022"
        print("CPU-Simulation-CLI, Paul Schütz/Paul Schuetz\nVersion \(version)\n\(date)")
        return
    }
    
	let fileIndex = parsedArgs.firstNonOption
	
	if fileIndex < 0 {
		print("No file is specified!")
		return
	}
	
    var fileName = args[fileIndex]
    
    if fileName.first != "/" {
        fileName = fm.currentDirectoryPath + "/" + fileName
    }
    
    if !fm.isReadableFile(atPath: fileName) {
        print("File is not readable or doesn't exist!")
        return
    }
    
    let assembler = try String(contentsOf: URL(fileURLWithPath: fileName))
    
    let mem = Memory()
    
    let cpu = CPU(memory: mem, startingPoint: s)
    
    do {
        let assemblingResult = try mem.loadAssembly(assemblyCode: assembler)


        if parsedArgs.instantRun {
            try operateWithFirstRun(cpu: cpu, assemblingResults: assemblingResult)
        } else {
            try operate(cpu: cpu, assemblingResults: assemblingResult)
        }
    } catch {
        print("Error: \(error)")
    }
}

func printSeparation() {
    print("\n\n\n\n\n")
}

func printSuccess() {
    print("Execution Successfull\n")
}

func increaseCycleCountIfNecessary(cpu: CPU) {
    if cpu.state == "executed" || cpu.state == "hold" {
        executionCycles &+= 1
    }
}

func operate(cpu: CPU, assemblingResults results: AssemblingResults) throws {
    var operationMode = OperationMode.stop
    let memory = cpu.memory
    
    repeat {
        
        printAll(cpu: cpu, mem: memory, assemblingResults: results)
        
        operationMode = getOperationMode(cpu: cpu)
        
        switch operationMode {
            case .nextStep:
                try cpu.operateNextStep()
                
                increaseCycleCountIfNecessary(cpu: cpu)
                
                printSeparation()
                printSuccess()
            case .endInstruction:
                try cpu.endInstruction()
                executionCycles &+= 1
                
                printSeparation()
                printSuccess()
            case .run:
                try cpu.run()
                executionCycles &+= cpu.cycleCount
                
                printSeparation()
                printSuccess()
            case .stop:
                break
        }
        
    } while operationMode != .stop
}

func operateWithFirstRun(cpu: CPU, assemblingResults results: AssemblingResults) throws {
    print("Instant Running")
    
    try cpu.run()
    
    printSuccess()
    
    executionCycles &+= cpu.cycleCount
    
    try operate(cpu: cpu, assemblingResults: results)
}

enum OperationMode {
    case nextStep
    case endInstruction
    case run
    case stop
}

func getCPUString(cpu: CPU, assemblingResults: AssemblingResults) -> String {
	let literalValueType = AssemblingResults.LiteralAddressValue(value: cpu.accumulator)
    
    let accuString = literalValueType.transform()
    
    var result = "CPU:\n"
    result += "State: \(cpu.state)\n\n"
    result += "Program Counter:  \(toLongHexString(cpu.programCounter))\n"
    result += "Stackpointer:     \(toLongHexString(cpu.stackpointer))\n"
    result += "Accumulator:      \(accuString)\n"
    result += "Execution Cycles: \(executionCycles)\n\n"
    result += "Flags: "
    
    result += "n" + (cpu.nFlag ? "*" : " ") + "    "
    result += "z" + (cpu.zFlag ? "*" : " ") + "    "
    result += "v" + (cpu.vFlag ? "*" : " ") + "\n\n"
    
    result += "Operator\t\(getOperatorString(cpu: cpu))\n"
    result += "Operand \t\(getOperandString(cpu: cpu, assemblingResult: assemblingResults))"
    
    result += "\n"
    
    return result
}

func getOperatorString(cpu: CPU) -> String {
    if cpu.operator != nil && cpu.operandType != nil {
        return cpu.operatorString + cpu.operandType!.representationAddition
    }
    
    return toLongHexString(cpu.opcode)
}

func getOperandString(cpu: CPU, assemblingResult result: AssemblingResults) -> String {
    let operandAddress = cpu.operatorProgramCounter &+ 1
    
	let valueType = result.memoryValues[operandAddress] ?? AssemblingResults.AddressAddressValue(value: cpu.operand)
    
    return valueType.transform()
}

func getMarkerOfAType(assemblingResults results: AssemblingResults, mem: Memory, markerType: AssemblingResults.Marker.`Type`, title: String) -> String {
    var result = "\(title)\n"
    let markers = results.markers.filter() { marker in
        marker.type == markerType
    }
    
    if markers.count < 1 {
        return ""
    }
    
    for marker in markers {
        
        result += "\"\(marker.name)\" at 0x\(toHexString(marker.address)): "
        
		let valueType = results.memoryValues[marker.address] ?? AssemblingResults.AddressAddressValue(value: mem.read(address: marker.address))
        
        let representation = valueType.transform()
        let numericRespresentation = valueType.transformOnlyNumber()
        
        result += representation
        
        if representation != numericRespresentation {
            result += " (\(numericRespresentation))"
        }
        
        result += "\n"
    }
    
    result += "\n"
    
    return result
}

func getMarkers(assemblingResults results: AssemblingResults, mem: Memory) -> String {
    
    var result = getMarkerOfAType(assemblingResults: results, mem: mem, markerType: .variable, title: "Variables:")
    
    result += getMarkerOfAType(assemblingResults: results, mem: mem, markerType: .jumpMarker, title: "Jump-Markers:")
    
    result += getMarkerOfAType(assemblingResults: results, mem: mem, markerType: .undefined, title: "Undefined Markers")
    
    return result
}

func getOperationMode(cpu: CPU) -> OperationMode {
    while true {
        print("What should be done next?")
        print("")
        
        print("'P' to print the memory without transformation or additional information")
        print("'H' to print the memory without transformation or additional information in hexadecimal format")
        print("'R' to run the CPU until the next HOLD-instruction")
        print("'S' to operate the next step")
        print("'E' to end the program")
        print("")
        
        print("Everything else will end the current instruction.")
        
        let answer = readLine()?.lowercased()
        
        switch answer {
            case "p":
                printMemory(memory: cpu.memory)
            case "h":
                printHexMemory(memory: cpu.memory)
            case "r":
                return .run
            case "s":
                return .nextStep
            case "e":
                return .stop
            default:
                return .endInstruction
        }
    }
}

func printMemory(memory: Memory) {
    print("\n\(memory.getString())\n")
}

func printHexMemory(memory: Memory) {
    print("\n\(memory.getHexString())\n")
}

func printAll(cpu: CPU, mem: Memory, assemblingResults: AssemblingResults) {
    let cpuString = getCPUString(cpu: cpu, assemblingResults: assemblingResults)
    let markers = getMarkers(assemblingResults: assemblingResults, mem: mem)
    let memory = getMemoryRepresentation(cpu: cpu, mem: mem, results: assemblingResults)
    
    print("\(cpuString)\n\(markers)\n\(memory)\n")
}

func parseCLIArgs(args: inout [String]) -> ArgsResults {
    var result = ArgsResults()
    
    var i = 1
    
    while i < args.count {
        let val = args[i]
        if val.lowercased() == "-s" {
            if i + 1 >= args.count {
                print("The starting point coudn't be read, there was no other parameter after '-s'\n\n")
                break
            }
            
            let param = args[i+1]
            
            let decimal = !param.contains() { char in !char.isNumber }
            var hexadecimal: Bool {
                let prefix = param.starts(with: "0x")
                
                let number = param.dropFirst().dropFirst()
                
                let numberAllowed = !number.contains() { char in !char.isHexDigit }
                
                return prefix && numberAllowed
            }
            
            if decimal {
                let nrI = Int(param)!
                if nrI > 0xFFFF{
                    continue
                }
                let nr = UInt16(nrI)
                args.remove(at: i)
                args.remove(at: i)
                
                i -= 2
                
                result.startingPoint = nr
            } else if hexadecimal {
                if args[i+1].count > 6 {
                    continue
                }
                let nr = try? hexFromString(param)
                
                args.remove(at: i)
                args.remove(at: i)
                result.startingPoint = nr
                
                i -= 2
            } else {
                print("The starting point coudn't be read, the parameter '\(param)' directely after '-s'\ncouldn't be converted into a number!\n\n")
            }
        } else if val.lowercased() == "-r" {
            result.instantRun = true
		} else if result.firstNonOption == -1 {
			result.firstNonOption = i
		}
        
        i += 1
    }
    return result
}

struct ArgsResults {
    var startingPoint: UInt16?
    var instantRun = false
	var firstNonOption: Int = -1
}
