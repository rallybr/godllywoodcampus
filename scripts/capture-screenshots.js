// @ts-check
import fs from 'fs';
import path from 'path';
import puppeteer from 'puppeteer';

const BASE_URL = process.env.BASE_URL || 'http://10.144.58.11:5173';
const OUTPUT_DIR = path.resolve('screenshots');

/** @type {{ url: string, name: string }[]} */
const routes = [
  { url: '/', name: 'home' },
  { url: '/jovens', name: 'jovens-list' },
  { url: '/avaliacoes', name: 'avaliacoes' },
  { url: '/relatorios', name: 'relatorios' },
  { url: '/relatorios/jovens', name: 'relatorios-jovens' },
  { url: '/relatorios/avaliacoes', name: 'relatorios-avaliacoes' },
  { url: '/relatorios/personalizados', name: 'relatorios-personalizados' },
  { url: '/estados/SP', name: 'estados-SP' },
  { url: '/usuarios', name: 'usuarios' },
  { url: '/viagem', name: 'viagem' },
  { url: '/config', name: 'config' },
  { url: '/profile', name: 'profile' },
  { url: '/login', name: 'login' },
  { url: '/register', name: 'register' },
  { url: '/forgot-password', name: 'forgot-password' },
  { url: '/reset-password', name: 'reset-password' },
  { url: '/seguranca', name: 'seguranca' },
  { url: '/seguranca/auditoria', name: 'seguranca-auditoria' },
  { url: '/seguranca/historico', name: 'seguranca-historico' },
  { url: '/seguranca/sessoes', name: 'seguranca-sessoes' }
];

/** @type {{ name: string, width: number, height: number, deviceScaleFactor?: number }[]} */
const viewports = [
  { name: 'iphone14pro', width: 393, height: 852, deviceScaleFactor: 3 },
  { name: 'android-small', width: 360, height: 740, deviceScaleFactor: 2 }
];

async function ensureDir(dir) {
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
}

async function capture() {
  await ensureDir(OUTPUT_DIR);
  const browser = await puppeteer.launch({ headless: 'new', args: ['--no-sandbox','--disable-setuid-sandbox'] });
  try {
    const page = await browser.newPage();
    page.setDefaultNavigationTimeout(60000);

    for (const vp of viewports) {
      await page.setViewport({ width: vp.width, height: vp.height, deviceScaleFactor: vp.deviceScaleFactor || 1, isMobile: true, hasTouch: true });
      const vpDir = path.join(OUTPUT_DIR, vp.name);
      await ensureDir(vpDir);

      for (const r of routes) {
        const url = `${BASE_URL}${r.url}`;
        try {
          await page.goto(url, { waitUntil: 'networkidle2' });
          await page.waitForTimeout(800);
          const file = path.join(vpDir, `${r.name}.png`);
          await page.screenshot({ path: file, fullPage: true });
          console.log(`Saved: ${file}`);
        } catch (e) {
          console.warn(`Failed: ${url} -> ${e?.message || e}`);
        }
      }
    }
  } finally {
    await browser.close();
  }
}

capture().catch((e) => {
  console.error(e);
  process.exit(1);
});


