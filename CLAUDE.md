# CRM Lojista — Contexto do Projeto

## O que é
CRM para lojistas de eletrônicos e produtos em geral. Arquivo único HTML com Supabase como backend (auth + banco). Vendável a R$350 avulso ou R$29,90/mês recorrente. Também existe uma versão Básica (localStorage) usada como bônus do Tabela Fone.

## Arquitetura
- **Frontend:** `crm-lojista.html` — arquivo único, vanilla JS, Supabase JS SDK via CDN, Chart.js, Google Fonts (Space Grotesk, Inter, IBM Plex Mono)
- **Backend:** Supabase (Postgres + Auth + RLS). Schema em `crm-schema.sql`
- **Storage:** Supabase Postgres com Row Level Security (cada lojista só vê seus dados)
- **Auth:** E-mail + senha via Supabase Auth
- **Deploy:** Qualquer hosting estático (GitHub Pages, Vercel, Netlify)

## Estrutura do banco (Supabase)
- `profiles` — dados da loja, % distribuição, garantia padrão (extends auth.users)
- `categories` — categorias customizáveis pelo lojista (nome + cor)
- `products` — catálogo de produtos com custo padrão e preço sugerido
- `sales` — vendas com todos os campos financeiros, status pagamento, garantia
- `stock_movements` — entradas e saídas de estoque
- `stock_balance` — view SQL que agrega saldo automaticamente

## Tabs do app
1. **Dashboard** — KPIs (faturamento, lucro, ticket médio, a receber), distribuição 20/30/50 configurável, gráficos
2. **Vendas** — CRUD completo com filtros, status pagamento (pago/parcial/não pago), garantia Apple/Lojista, reparo
3. **Estoque** — entrada/saída, saldo consolidado, custo médio
4. **Catálogo** — produtos com custo/preço sugerido, autocomplete na venda
5. **Configurações** — nome da loja, % distribuição, garantia padrão, CRUD de categorias

## Regras de negócio
- Lucro = Venda − (custo + frete + brindes + reparo + uber + embalagem) − indicação
- Distribuição do lucro incide APENAS sobre o lucro já recebido (vendas Pago + fração paga do Parcial)
- Vendas "Não pago" e parte não paga do "Parcial" ficam no painel "A receber", sem entrar na distribuição
- Percentuais de distribuição são configuráveis por lojista (padrão: 20% reserva, 30% pró-labore, 50% reinvestimento)

## Configuração
No topo do `<script>` em `crm-lojista.html`:
```js
const SUPABASE_URL = 'SUA_URL_AQUI';
const SUPABASE_KEY = 'SUA_CHAVE_ANON_AQUI';
```

## Convenções de código
- IDs de elementos HTML curtos e descritivos (prefixo por seção: `v` vendas, `s` estoque, `p` catálogo, `d` dashboard)
- Funções de render: `renderDashboard()`, `renderSales()`, `renderStock()`, `renderCatalog()`, `renderConfig()`
- Estado global: `user`, `profile`, `categories`, `products`, `sales`, `stockMov`
- CSS usa custom properties em `:root` para theming
- Paleta: ink (#11182B), gold (#C8872E), teal (#2F7A6F), coral (#C84B36), blue (#2A4A8C)

## Dono do projeto
Mateus — desenvolvedor e empreendedor no Rio de Janeiro. Trabalha com revenda de iPhones (L8 PRAVOCÊ) e medicamentos. Supabase account: processolead@gmail.com.

## Próximos passos planejados
- Conectar ao Supabase real (URL + key)
- Importar dados históricos da versão localStorage (128 vendas existentes)
- PWA completo (service worker para offline)
- Versão Básica (localStorage) como bônus do Tabela Fone
- Página de landing / checkout para venda do CRM Pro
