"use client";
import { create } from "zustand";
import { ReactNode } from "react";

interface ShellStoreState {
  history: ReactNode[];
  addLine: (line: ReactNode) => void;
  clearHistory: () => void;
}

const useShellStore = create<ShellStoreState>((set) => ({
  history: [],
  addLine: (line: ReactNode) =>
    set((state) => ({ history: [...state.history, line] })),
  clearHistory: () => set({ history: [] }),
}));

export default useShellStore;
