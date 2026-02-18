import { useState } from 'react';
import { generateZKProof, verifyProofOnChain } from '@/services/zkProofService';

export const useZKProof = () => {
  const [isGenerating, setIsGenerating] = useState(false);
  const [proof, setProof] = useState<string | null>(null);

  const createProof = async (data: any) => {
    setIsGenerating(true);
    try {
      const result = await generateZKProof(data);
      setProof(result.proof);
      return result;
    } finally {
      setIsGenerating(false);
    }
  };

  return { createProof, isGenerating, proof };
};
