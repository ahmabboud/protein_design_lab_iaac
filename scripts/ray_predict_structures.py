#!/usr/bin/env python
# Script to predict protein structures from sequences using Ray and ESMFold

import argparse
import os
import ray
import json
import torch
import numpy as np
from pathlib import Path
from datetime import datetime
from Bio import SeqIO

def parse_args():
    parser = argparse.ArgumentParser(description='Predict protein structures using Ray')
    parser.add_argument('--input-dir', type=str, default='/opt/ml/input/data/training',
                        help='Directory containing input sequences')
    parser.add_argument('--output-dir', type=str, default='/opt/ml/model/structures',
                        help='Directory to save predicted structures')
    parser.add_argument('--batch-size', type=int, default=4,
                        help='Batch size for predictions')
    parser.add_argument('--max-length', type=int, default=500,
                        help='Maximum sequence length to predict')
    return parser.parse_args()

# Pre-import libraries to detect import errors early
try:
    import esm
    HAS_ESM = True
except ImportError:
    print("WARNING: ESMFold not installed. Will attempt to install when needed.")
    HAS_ESM = False

@ray.remote(num_gpus=1)
def predict_structure_batch(sequences, output_dir):
    """Predict structures for a batch of sequences using ESMFold"""
    try:
        import torch
        import biotite.structure.io as bsio
        
        # Only import ESM if we haven't already checked it
        if not 'esm' in globals():
            try:
                import esm
            except ImportError:
                print("Installing ESMFold...")
                import subprocess
                subprocess.check_call(["pip", "install", "fair-esm"])
                import esm
        
        # Load the model
        model = esm.pretrained.esmfold_v1()
        model.eval()
        
        results = []
        
        for seq_id, seq in sequences:
            if len(seq) > 1000:
                results.append({
                    "sequence_id": seq_id,
                    "status": "skipped",
                    "reason": f"Sequence too long: {len(seq)} > 1000"
                })
                continue
                
            try:
                # Predict structure
                with torch.no_grad():
                    output = model.infer_pdb(seq)
                
                # Save as PDB file
                output_path = os.path.join(output_dir, f"{seq_id}.pdb")
                with open(output_path, 'w') as f:
                    f.write(output)
                
                # Record successful prediction
                results.append({
                    "sequence_id": seq_id,
                    "length": len(seq),
                    "output_path": output_path,
                    "status": "success"
                })
            except Exception as e:
                results.append({
                    "sequence_id": seq_id,
                    "status": "failed",
                    "error": str(e)
                })
        
        return results
        
    except Exception as e:
        return [{
            "batch_error": str(e),
            "status": "batch_failed"
        }]

def load_sequences(input_dir):
    """Load sequences from FASTA files"""
    sequences = []
    
    for fasta_file in Path(input_dir).glob("**/*.fasta"):
        for record in SeqIO.parse(fasta_file, "fasta"):
            seq_id = record.id
            sequence = str(record.seq)
            sequences.append((seq_id, sequence))
    
    return sequences

def main():
    args = parse_args()
    
    # Initialize Ray
    ray.init()
    
    # Create output directory
    os.makedirs(args.output_dir, exist_ok=True)
    
    # Load sequences
    sequences = load_sequences(args.input_dir)
    print(f"Loaded {len(sequences)} sequences")
    
    # Create batches
    batches = [
        sequences[i:i+args.batch_size] 
        for i in range(0, len(sequences), args.batch_size)
    ]
    
    # Submit tasks
    tasks = []
    for batch in batches:
        task = predict_structure_batch.remote(batch, args.output_dir)
        tasks.append(task)
    
    # Wait for results
    batch_results = ray.get(tasks)
    
    # Flatten results
    results = [item for sublist in batch_results for item in sublist]
    
    # Save summary
    with open(os.path.join(args.output_dir, "prediction_summary.json"), "w") as f:
        json.dump({
            "timestamp": datetime.now().isoformat(),
            "total_sequences": len(sequences),
            "successful_predictions": sum(1 for r in results if r.get("status") == "success"),
            "failed_predictions": sum(1 for r in results if r.get("status") == "failed"),
            "skipped_predictions": sum(1 for r in results if r.get("status") == "skipped"),
            "results": results
        }, f, indent=2)
    
    print("Structure prediction complete")

if __name__ == "__main__":
    main()
