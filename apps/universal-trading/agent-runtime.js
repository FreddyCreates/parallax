export class FinanceAgentRuntime {
  constructor({ routeEngine, receiptSink = null, now = () => Date.now() }) {
    this.routeEngine = routeEngine;
    this.receiptSink = receiptSink;
    this.now = now;
    this.deployments = new Map();
  }

  deploy(spec) {
    const errors = this.validateSpec(spec);
    if (errors.length) return { ok: false, errors };

    const deployment = {
      deploymentId: spec.deploymentId || crypto.randomUUID(),
      templateId: spec.templateId,
      owner: spec.owner,
      mode: spec.mode,
      allowedChains: [...spec.allowedChains],
      allowedAssets: [...spec.allowedAssets],
      maxOrderValueUsd: Number(spec.maxOrderValueUsd),
      dailyLimitUsd: Number(spec.dailyLimitUsd),
      humanApprovalAboveUsd: Number(spec.humanApprovalAboveUsd),
      status: 'paused',
      createdAt: this.now(),
      updatedAt: this.now(),
      spentTodayUsd: 0,
      haltReason: null
    };
    this.deployments.set(deployment.deploymentId, deployment);
    return { ok: true, deployment: this.publicDeployment(deployment), receipt: this.receipt('agent_deployed', deployment) };
  }

  validateSpec(spec) {
    const errors = [];
    if (!spec?.templateId) errors.push('template_id_required');
    if (!spec?.owner) errors.push('owner_required');
    if (!['paper', 'testnet'].includes(spec?.mode)) errors.push('live_agent_mode_blocked');
    if (!Array.isArray(spec?.allowedChains) || !spec.allowedChains.length) errors.push('allowed_chains_required');
    if (!Array.isArray(spec?.allowedAssets) || !spec.allowedAssets.length) errors.push('allowed_assets_required');
    for (const key of ['maxOrderValueUsd', 'dailyLimitUsd', 'humanApprovalAboveUsd']) {
      if (!Number.isFinite(Number(spec?.[key])) || Number(spec[key]) <= 0) errors.push(`${key}_invalid`);
    }
    return errors;
  }

  setStatus(deploymentId, status, reason = null) {
    const deployment = this.deployments.get(deploymentId);
    if (!deployment) return { ok: false, errors: ['deployment_not_found'] };
    if (!['active', 'paused', 'halted'].includes(status)) return { ok: false, errors: ['invalid_status'] };
    deployment.status = status;
    deployment.haltReason = status === 'halted' ? reason || 'operator_halt' : null;
    deployment.updatedAt = this.now();
    return { ok: true, deployment: this.publicDeployment(deployment), receipt: this.receipt(`agent_${status}`, deployment) };
  }

  async evaluateOrder(deploymentId, order, approval = null) {
    const deployment = this.deployments.get(deploymentId);
    const errors = [];
    if (!deployment) return { ok: false, errors: ['deployment_not_found'] };
    if (deployment.status !== 'active') errors.push(`agent_${deployment.status}`);
    if (!deployment.allowedChains.includes(order.chainId)) errors.push('chain_not_allowed');
    if (!deployment.allowedAssets.includes(order.sellAsset) || !deployment.allowedAssets.includes(order.buyAsset)) errors.push('asset_not_allowed');
    const valueUsd = Number(order.valueUsd);
    if (!Number.isFinite(valueUsd) || valueUsd <= 0) errors.push('order_value_invalid');
    if (valueUsd > deployment.maxOrderValueUsd) errors.push('max_order_value_exceeded');
    if (deployment.spentTodayUsd + valueUsd > deployment.dailyLimitUsd) errors.push('daily_limit_exceeded');
    if (valueUsd >= deployment.humanApprovalAboveUsd && approval?.approvedBy === deployment.owner) errors.push('agent_self_approval_blocked');
    if (valueUsd >= deployment.humanApprovalAboveUsd && !approval?.approvedBy) errors.push('human_approval_required');
    if (order.mode !== deployment.mode) errors.push('mode_mismatch');
    if (errors.length) return { ok: false, errors, receipt: this.receipt('agent_order_rejected', { deploymentId, order, errors }) };

    const quote = await this.routeEngine.quote(order);
    if (!quote.ok) return { ok: false, errors: quote.errors || ['route_unavailable'], receipt: quote.receipt || null };
    deployment.spentTodayUsd += valueUsd;
    deployment.updatedAt = this.now();
    return {
      ok: true,
      status: 'policy_approved_simulation',
      quote,
      deployment: this.publicDeployment(deployment),
      receipt: this.receipt('agent_order_approved', { deploymentId, order, quoteReceiptId: quote.receipt.receiptId })
    };
  }

  publicDeployment(deployment) {
    const { spentTodayUsd, ...publicFields } = deployment;
    return { ...publicFields, spentTodayUsd };
  }

  receipt(kind, payload) {
    const receipt = {
      receiptId: `${kind}:${crypto.randomUUID()}`,
      kind,
      createdAt: this.now(),
      payload,
      mainnetExecution: false
    };
    if (this.receiptSink) this.receiptSink(receipt);
    return receipt;
  }
}
