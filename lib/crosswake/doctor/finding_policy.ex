defmodule Crosswake.Doctor.FindingPolicy do
  @moduledoc """
  Central Phase 18 finding taxonomy for proof posture and support-claim severity.
  """

  @type shell_proof_status :: :passed | :failed | :missing | :verification_required
  @type support_status :: :supported | :verification_required

  @spec shell_proof(shell_proof_status(), String.t(), String.t()) ::
          {atom(), String.t(), String.t()}
  def shell_proof(:passed, _label, _script_path) do
    {:advisory, "proof_hook_passed",
     "generated-project proof passed on the same host-owned artifact class adopters ship"}
  end

  def shell_proof(:failed, label, _script_path) do
    {:error, "proof_hook_failed",
     "fix the proof hook failure before treating #{label} shell support as supported"}
  end

  def shell_proof(:missing, label, script_path) do
    {:error, "proof_hook_missing",
     "restore #{script_path} before claiming #{label} shell support"}
  end

  def shell_proof(:verification_required, label, script_path) do
    {:warning, "proof_hook_verification_required",
     "run #{script_path} through mix crosswake.doctor --native-checks before claiming #{label} shell support"}
  end

  @spec support_claim(support_status()) :: {atom(), String.t(), String.t(), String.t()}
  def support_claim(:supported) do
    {:advisory, "support_claim_supported",
     "shell support claims are unlocked because the currently tracked generated-project proof hooks passed",
     "keep host-owned iOS and Android proof hooks green before widening public support"}
  end

  def support_claim(:verification_required) do
    {:warning, "support_claim_verification_required",
     "support claims remain verification required until the tracked generated-project proof hooks pass",
     "run mix crosswake.doctor --native-checks after the host-owned shell projects and proof hooks are in place"}
  end
end
