import { PHASES, type PhaseKey, type PhaseState, type PhaseStatus } from "@neoxp/contracts";
import { getNextPhase, isKnownPhase } from "./phase-flow.js";

export interface WorkflowSnapshot {
  current: PhaseKey;
  phases: PhaseState[];
}

export class WorkflowStateMachine {
  private state: WorkflowSnapshot;

  constructor(start: PhaseKey = "phase1_language") {
    this.state = {
      current: start,
      phases: PHASES.map((key): PhaseState => ({
        key,
        status: key === start ? "active" : "todo"
      }))
    };
  }

  public getSnapshot(): WorkflowSnapshot {
    return {
      current: this.state.current,
      phases: this.state.phases.map((item) => ({ ...item }))
    };
  }

  public setStatus(phase: PhaseKey, status: PhaseStatus): void {
    const row = this.state.phases.find((item) => item.key === phase);
    if (!row) return;
    row.status = status;
  }

  public canJumpTo(target: string): target is PhaseKey {
    if (!isKnownPhase(target)) return false;
    const targetRow = this.state.phases.find((item) => item.key === target);
    if (!targetRow) return false;
    if (target === this.state.current) return true;
    if (targetRow.status === "done") return true;
    if (targetRow.status === "active") return true;

    const currentIndex = PHASES.indexOf(this.state.current);
    const targetIndex = PHASES.indexOf(target);
    return targetIndex <= currentIndex + 1;
  }

  public jumpTo(target: string): boolean {
    if (!this.canJumpTo(target)) return false;
    const targetKey = target as PhaseKey;

    for (const row of this.state.phases) {
      if (row.key === this.state.current && row.status === "active") {
        row.status = "done";
      }
      if (row.key === targetKey) {
        row.status = "active";
      }
    }
    this.state.current = targetKey;
    return true;
  }

  public advance(): PhaseKey | null {
    const next = getNextPhase(this.state.current);
    if (!next) return null;
    this.jumpTo(next);
    return next;
  }
}

