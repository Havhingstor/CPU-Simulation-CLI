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
        fileName = fm.currentDirectoryPath + "/" + fileName
    }
    
    if !fm.isReadableFile(atPath: fileName) {
        print("File is not readable or doesn't exist!")
        return
    }
    
    let assembler = try String(contentsOf: URL(fileURLWithPath: fileName))
    
    let mem = Memory()
    
    _ = parseAssembler(input: assembler, mem: mem)
    
    let cpu = CPU(memory: mem)
    
    var continueRunning = true
    
    while continueRunning {
        continueRunning = cpu.run()
        
        if continueRunning {
            print("Code executed successfull.")
        } else {
            print("Code executed unsuccessfull!")
        }
        
        print("\n" + String(describing: mem))
        
        if continueRunning {
            print("Should the CPU continue running?\n'C' to continue, else the execution will be exited.")
            let answer = readLine()
            
            if answer != "C" {
                continueRunning = false
            }
        }
    }
}
