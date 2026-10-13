# GemHub frontend

Create React App 5 with React 18 and TypeScript 4. The checked-in `tsconfig.json` and `src/react-app-env.d.ts` are required for CRA to recognize the TypeScript entry point and App module.

```bash
npm ci --ignore-scripts --no-audit --no-fund
npm run lint
CI=true npm run build
npm start
```

The development proxy targets the Ruby API at `http://localhost:4567`. Build and lint checks do not verify that service or marketplace mutations. Create Gem, Sandbox, and Benchmarks currently contain coming-soon interfaces; a successful build does not make them implemented features.
