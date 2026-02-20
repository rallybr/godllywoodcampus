/**
 * Script para criar os buckets de Storage do Godllywood Campus no Supabase.
 *
 * Uso:
 *   1. Crie um .env.local com SUPABASE_SERVICE_ROLE_KEY (chave service_role do projeto).
 *   2. Ou defina variável de ambiente: set SUPABASE_SERVICE_ROLE_KEY=sua_chave
 *   3. node supabase/scripts/create-storage-buckets.js
 *
 * Requer: @supabase/supabase-js (já é dependência do projeto).
 * A VITE_SUPABASE_URL é lida do .env do projeto.
 */

import { createClient } from '@supabase/supabase-js';
import { readFileSync, existsSync } from 'fs';
import { resolve } from 'path';

const ENV_PATH = resolve(process.cwd(), '.env');
const ENV_LOCAL_PATH = resolve(process.cwd(), '.env.local');

function loadEnv() {
  const env = {};
  for (const p of [ENV_PATH, ENV_LOCAL_PATH]) {
    if (!existsSync(p)) continue;
    const content = readFileSync(p, 'utf8');
    for (const line of content.split('\n')) {
      const m = line.match(/^\s*([^#=]+)=(.*)$/);
      if (m) env[m[1].trim()] = m[2].trim().replace(/^["']|["']$/g, '');
    }
  }
  return env;
}

const env = loadEnv();
const url = process.env.VITE_SUPABASE_URL || env.VITE_SUPABASE_URL;
const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY || env.SUPABASE_SERVICE_ROLE_KEY;

if (!url || !serviceRoleKey) {
  console.error('Defina VITE_SUPABASE_URL e SUPABASE_SERVICE_ROLE_KEY (em .env ou .env.local).');
  process.exit(1);
}

const supabase = createClient(url, serviceRoleKey);

const BUCKETS = [
  { name: 'fotos_usuarios', public: true, fileSizeLimit: 5242880 },   // 5MB
  { name: 'fotos_jovens', public: true, fileSizeLimit: 5242880 },
  { name: 'viagens', public: true, fileSizeLimit: 10485760 },         // 10MB (PDFs)
  { name: 'fotos_nucleos', public: true, fileSizeLimit: 5242880 },
];

async function main() {
  for (const b of BUCKETS) {
    const { data, error } = await supabase.storage.createBucket(b.name, {
      public: b.public,
      fileSizeLimit: b.fileSizeLimit,
      allowedMimeTypes: ['image/jpeg', 'image/png', 'image/webp', 'image/jpg', 'application/pdf'],
    });
    if (error) {
      if (error.message?.includes('already exists') || error.message?.includes('Bucket already exists')) {
        console.log(`Bucket "${b.name}" já existe.`);
      } else {
        console.error(`Erro ao criar bucket "${b.name}":`, error.message);
      }
    } else {
      console.log(`Bucket "${b.name}" criado.`);
    }
  }
  console.log('\nPróximo passo: execute o SQL em supabase/storage_buckets_e_policies.sql no SQL Editor do Supabase.');
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
