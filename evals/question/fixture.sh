#!/usr/bin/env bash
# Build the small TypeScript repository shared by the eval cases in an empty workspace.
# Each case's fixture.sh is a copy of this file (scaffold_script must live in the case directory).
# After editing, run scripts/sync-eval-fixtures.sh to update the copies.
# The demo content and the case prompts are in Japanese on purpose: they also check that APD replies in the user's language.
set -euo pipefail

mkdir -p src

cat > package.json <<'JSON'
{
  "name": "demo-shop",
  "private": true,
  "type": "module",
  "scripts": { "dev": "vite", "test": "vitest run" },
  "dependencies": { "react": "^19.0.0", "react-dom": "^19.0.0" },
  "devDependencies": { "typescript": "^5.6.0", "vite": "^6.0.0", "vitest": "^3.0.0" }
}
JSON

cat > README.md <<'MD'
# demo-shop

小さな EC サイトのデモ。

## Instalation

```
npm install
npm run dev
```
MD

cat > src/format.ts <<'TS'
export function formatPrice(yen: number): string {
  return `¥${yen.toLocaleString("ja-JP")}`;
}
TS

cat > src/cart.ts <<'TS'
import { formatPrice } from "./format";

export type Item = { name: string; price: number; qty: number };

export function cartTotal(items: Item[]): string {
  return formatPrice(items.reduce((sum, i) => sum + i.price * i.qty, 0));
}
TS

cat > src/App.tsx <<'TSX'
import { cartTotal } from "./cart";

export function App() {
  return <p>合計: {cartTotal([{ name: "りんご", price: 120, qty: 3 }])}</p>;
}
TSX

git init -q
git -c user.email=eval@example.com -c user.name=eval add -A
git -c user.email=eval@example.com -c user.name=eval commit -qm "init"
