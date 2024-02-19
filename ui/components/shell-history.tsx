'use client'
import useShellStore from "@/lib/use-shell-store"

export const ShellHistory = () => {
    const history = useShellStore(state => state.history)

    return (
        <div>
            {history.map((line, i) => (
                <div className="mt-1" key={i}>{line}</div>
            ))}
        </div>
    )
}

