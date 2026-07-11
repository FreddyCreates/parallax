import Types "Types";

module {
  private func pair(
    pairId : Text,
    display : Text,
    base : Text,
    quote : Text,
    category : Types.MarketCategory,
    description : Text,
    status : Types.MarketStatus,
  ) : Types.PairInfo {
    {
      pairId = pairId;
      display = display;
      base = base;
      quote = quote;
      category = category;
      status = status;
      description = description;
      tickSizeE8s = 10_000;
      minOrderE8s = 100_000;
      makerFeeBps = 0;
      takerFeeBps = 5;
      maxOpenOrdersPerPrincipal = 100;
      settlementIntervalMs = 873;
    }
  };

  public func seedPairs() : [Types.PairInfo] {
    [
      pair("GTK_ICP", "GTK/ICP", "GTK", "ICP", #sovereign, "Governance Token — protocol voting rights", #enabled),
      pair("MTC_ICP", "MTC/ICP", "MTC", "ICP", #sovereign, "Materia Cogitans — AI compute settlement unit", #enabled),
      pair("MTH_ICP", "MTH/ICP", "MTH", "ICP", #sovereign, "Methane — energy and resource pricing token", #enabled),
      pair("BTC_ICP", "BTC/ICP", "BTC", "ICP", #crypto, "Bitcoin via ckBTC / chain-key metadata", #enabled),
      pair("ETH_ICP", "ETH/ICP", "ETH", "ICP", #crypto, "Ethereum via ckETH / chain-key metadata", #enabled),
      pair("AICPU_ICP", "AICPU/ICP", "AICPU", "ICP", #ai_tokens, "General AI compute credits", #enabled),
      pair("AIMEM_ICP", "AIMEM/ICP", "AIMEM", "ICP", #ai_tokens, "AI memory allocation units", #enabled),
      pair("AIINF_ICP", "AIINF/ICP", "AIINF", "ICP", #ai_tokens, "Inference execution credits", #enabled),
      pair("AITRAIN_ICP", "AITRAIN/ICP", "AITRAIN", "ICP", #ai_tokens, "Training compute allocation", #enabled),
      pair("AIDATA_ICP", "AIDATA/ICP", "AIDATA", "ICP", #ai_tokens, "Dataset access and storage", #enabled),
      pair("AIGPU_ICP", "AIGPU/ICP", "AIGPU", "ICP", #ai_tokens, "GPU compute hours", #enabled),
      pair("AITPU_ICP", "AITPU/ICP", "AITPU", "ICP", #ai_tokens, "TPU compute allocation", #enabled),
      pair("AIBW_ICP", "AIBW/ICP", "AIBW", "ICP", #ai_tokens, "Network bandwidth credits", #enabled),
      pair("AIST_ICP", "AIST/ICP", "AIST", "ICP", #ai_tokens, "Persistent storage allocation", #enabled),
      pair("AIFT_ICP", "AIFT/ICP", "AIFT", "ICP", #ai_tokens, "Fine-tuning compute credits", #enabled),
      pair("AIEMB_ICP", "AIEMB/ICP", "AIEMB", "ICP", #ai_tokens, "Embedding generation credits", #enabled),
      pair("AIRAG_ICP", "AIRAG/ICP", "AIRAG", "ICP", #ai_tokens, "RAG pipeline execution credits", #enabled),
      pair("AIAGENT_ICP", "AIAGENT/ICP", "AIAGENT", "ICP", #ai_tokens, "Agent execution time", #enabled),
      pair("AIORCH_ICP", "AIORCH/ICP", "AIORCH", "ICP", #ai_tokens, "Orchestration and workflow credits", #enabled),
      pair("AICHAIN_ICP", "AICHAIN/ICP", "AICHAIN", "ICP", #ai_tokens, "Reasoning chain execution", #enabled),
      pair("AIVIS_ICP", "AIVIS/ICP", "AIVIS", "ICP", #ai_tokens, "Vision model inference", #enabled),
      pair("AIAUD_ICP", "AIAUD/ICP", "AIAUD", "ICP", #ai_tokens, "Audio model processing", #enabled),
      pair("AICODE_ICP", "AICODE/ICP", "AICODE", "ICP", #ai_tokens, "Code generation credits", #enabled),
      pair("AITRANS_ICP", "AITRANS/ICP", "AITRANS", "ICP", #ai_tokens, "Translation model access", #enabled),
      pair("AISENT_ICP", "AISENT/ICP", "AISENT", "ICP", #ai_tokens, "Sentiment analysis", #enabled),
      pair("AIANOM_ICP", "AIANOM/ICP", "AIANOM", "ICP", #ai_tokens, "Anomaly detection", #enabled),
      pair("AIPRED_ICP", "AIPRED/ICP", "AIPRED", "ICP", #ai_tokens, "Prediction model queries", #enabled),
      pair("AIOPT_ICP", "AIOPT/ICP", "AIOPT", "ICP", #ai_tokens, "Optimization credits", #enabled),
      pair("AISIM_ICP", "AISIM/ICP", "AISIM", "ICP", #ai_tokens, "Simulation execution", #enabled),
      pair("AIMVOTE_ICP", "AIMVOTE/ICP", "AIMVOTE", "ICP", #ai_tokens, "Model governance votes", #enabled),
      pair("AIDVOTE_ICP", "AIDVOTE/ICP", "AIDVOTE", "ICP", #ai_tokens, "Dataset governance votes", #enabled),
      pair("AISAFE_ICP", "AISAFE/ICP", "AISAFE", "ICP", #ai_tokens, "Safety audit credits", #enabled),
      pair("AIRED_ICP", "AIRED/ICP", "AIRED", "ICP", #ai_tokens, "Red-team evaluation credits", #enabled),
      pair("AIBENCH_ICP", "AIBENCH/ICP", "AIBENCH", "ICP", #ai_tokens, "Benchmark certification", #enabled),
      pair("AICERT_ICP", "AICERT/ICP", "AICERT", "ICP", #ai_tokens, "Model certification tokens", #enabled),
      pair("AILABEL_ICP", "AILABEL/ICP", "AILABEL", "ICP", #ai_tokens, "Human/agent labeling credits", #enabled),
      pair("AIPROMPT_ICP", "AIPROMPT/ICP", "AIPROMPT", "ICP", #ai_tokens, "Prompt/program synthesis credits", #enabled),
      pair("AITOOL_ICP", "AITOOL/ICP", "AITOOL", "ICP", #ai_tokens, "Tool-use execution credits", #enabled),
      pair("AIMON_ICP", "AIMON/ICP", "AIMON", "ICP", #ai_tokens, "Monitoring and telemetry credits", #enabled),
      pair("AIGUARD_ICP", "AIGUARD/ICP", "AIGUARD", "ICP", #ai_tokens, "Guardrail and policy execution credits", #enabled),
      pair("AICACHE_ICP", "AICACHE/ICP", "AICACHE", "ICP", #ai_tokens, "Cache and retrieval acceleration credits", #enabled),
      pair("AIRUNTIME_ICP", "AIRUNTIME/ICP", "AIRUNTIME", "ICP", #ai_tokens, "Runtime container execution credits", #enabled),
      pair("AIMDL_MTC", "AIMDL/MTC", "AIMDL", "MTC", #ai_artifacts, "Foundation, fine-tuned, LoRA, merged, and quantized model artifacts", #enabled),
      pair("AIEMB_MTC", "AIEMB/MTC", "AIEMB", "MTC", #ai_artifacts, "Embedding models and vector representations", #enabled),
      pair("AIPROT_MTC", "AIPROT/MTC", "AIPROT", "MTC", #ai_artifacts, "AI alignment, safety, and operating protocols", #enabled),
      pair("AIAGENT_MTC", "AIAGENT/MTC", "AIAGENT", "MTC", #ai_artifacts, "Autonomous agent systems with tools, memory, and workflows", #enabled),
      pair("AIORCH_MTC", "AIORCH/MTC", "AIORCH", "MTC", #ai_artifacts, "Orchestrators, evaluators, personas, and workflow templates", #enabled),
      pair("AIRAG_MTC", "AIRAG/MTC", "AIRAG", "MTC", #ai_artifacts, "RAG pipelines, vector databases, rerankers, and chunking strategies", #enabled),
      pair("AIDATA_MTC", "AIDATA/MTC", "AIDATA", "MTC", #ai_artifacts, "Synthetic, labeled, preference, multilingual, and domain datasets", #enabled),
      pair("AITUNE_MTC", "AITUNE/MTC", "AITUNE", "MTC", #ai_artifacts, "Instruction-tuning and adaptation recipes", #enabled),
      pair("AIEVAL_MTC", "AIEVAL/MTC", "AIEVAL", "MTC", #ai_artifacts, "Evaluation suites, scoring rubrics, and benchmark harnesses", #enabled),
      pair("AITWIN_MTC", "AITWIN/MTC", "AITWIN", "MTC", #ai_artifacts, "Digital twin and simulation systems", #enabled),
      pair("CREATOR_ICP", "CREATOR/ICP", "CREATOR", "ICP", #creator, "Generic creator economy index placeholder", #enabled),
      pair("CREATOR_MTC", "CREATOR/MTC", "CREATOR", "MTC", #creator, "Creator economy artifact settlement placeholder", #enabled),
      pair("SOL_ICP", "SOL/ICP", "SOL", "ICP", #crypto, "Solana research bridge placeholder", #disabled),
      pair("USDC_ICP", "USDC/ICP", "USDC", "ICP", #crypto, "Stablecoin bridge placeholder", #disabled),
      pair("USDT_ICP", "USDT/ICP", "USDT", "ICP", #crypto, "Stablecoin bridge placeholder", #disabled),
      pair("DOT_ICP", "DOT/ICP", "DOT", "ICP", #crypto, "Polkadot cross-chain research placeholder", #disabled),
      pair("ATOM_ICP", "ATOM/ICP", "ATOM", "ICP", #crypto, "Cosmos bridge research placeholder", #disabled)
    ]
  };
}
