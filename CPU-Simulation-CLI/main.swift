//
//  main.swift
//  CPU-Simulation-CLI
//
//  Created by Paul on 20.12.21.
//

import Foundation
import CPU_Simulation_Lib

try main()

func main() throws {
    let args = CommandLine.arguments
    
    if args.count < 2 {
        print("No file is specified!")
        return
    }
    
    let fm = FileManager.default
    
    if args[1] == "-h" {
        print("Specify the location of a assembler-file!")
        return
    }
    
    var fileName = args[1]
    
    if fileName.first != "/" {
        fileName = fm.currentDirectoryPath + fileName
    }
    
    if !fm.isReadableFile(atPath: fileName) {
        return
    }
    
    let assembler = try String(contentsOf: URL(fileURLWithPath: fileName))
    
    let mem = Memory()
    
    _ = parseAssembler(input: assembler, mem: mem)
    
    let cpu = CPU(memory: mem)
    
    let success = cpu.run()
    
    if success {
        print("Code executed successfull.")
    } else {
        print("Code executed unsuccessfull!")
    }
    
    print("\n" + String(describing: mem))
}
