#!/usr/bin/env python
# Script to generate protein sequences using Ray and ProteinMPNN

import argparse
import os
import ray
import json
import numpy as np
from datetime import datetime
from pathlib import Path

def parse_args():
    parser = argparse.ArgumentParser(description='Generate protein sequences using Ray')
    parser.add_argument('--input-dir', type=str, default='/opt/ml/processing/input',
                        help='Directory containing input structures')
    parser.add_argument('--output-dir', type=str, default='/opt/ml/processing/output',
                        help='Directory to save generated sequences')
    parser.add_argument('--num-sequences', type=int, default=50,
                        help='Number of sequences to generate per structure')
    parser.add_argument('--temperature', type=float, default=0.1, 
                        help='Sampling temperature')
    parser.add_argument('--seed', type=int, default=42,
                        help='Random seed')
    return parser.parse_args()

@ray.remote
def generate_sequences_for_structure(structure_path, num_sequences, temperature, output_dir, seed):
    """Generate sequences for a given protein structure using ProteinMPNN"""
    try:
        from proteinmpnn.protein_mpnn_utils import ProteinMPNN
        
        model = ProteinMPNN()
        
        # Generate sequences
        output_path = os.path.join(output_dir, os.path.basename(structure_path).replace('.pdb', '.fasta'))
        sequences = model.generate_sequences(
            pdb_path=structure_path,
            num_sequences=num_sequences,
            temperature=temperature,
            seed=seed
        )
        
        # Write sequences to FASTA file
        with open(output_path, 'w') as f:
            for i, seq in enumerate(sequences):
                f.write(f">design_{i+1}\n{seq}\n")
        
        return {
            "structure": os.path.basename(structure_path),
            "sequences_generated": len(sequences),
            "output_path": output_path,
            "status": "success"
        }
    except Exception as e:
        return {
            "structure": os.path.basename(structure_path),
            "error": str(e),
            "status": "failed"
        }

def main():
    args = parse_args()
    
    # Initialize Ray
    ray.init()
    
    # Create output directory
    os.makedirs(args.output_dir, exist_ok=True)
    
    # Find PDB files
    input_files = list(Path(args.input_dir).glob("**/*.pdb"))
    print(f"Found {len(input_files)} PDB files to process")
    
    # Submit tasks
    tasks = []
    for structure_path in input_files:
        task = generate_sequences_for_structure.remote(
            str(structure_path),
            args.num_sequences,
            args.temperature,
            args.output_dir,
            args.seed
        )
        tasks.append(task)
    
    # Wait for results
    results = ray.get(tasks)
    
    # Save summary
    with open(os.path.join(args.output_dir, "generation_summary.json"), "w") as f:
        json.dump({
            "timestamp": datetime.now().isoformat(),
            "total_structures": len(input_files),
            "successful_generations": sum(1 for r in results if r["status"] == "success"),
            "failed_generations": sum(1 for r in results if r["status"] == "failed"),
            "results": results
        }, f, indent=2)
    
    print("Sequence generation complete")

if __name__ == "__main__":
    main()
