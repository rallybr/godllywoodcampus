/**
 * Exibe apenas o 1º e o 2º nome do avaliador.
 * Nomes curtos (ex.: Bp, Pr, D.) contam como primeiro nome.
 * Exemplos: "Bp Celso Junior" → "Bp Celso"; "Marcos Vinicius de Souza" → "Marcos Vinicius"
 */
export function formatarNomeAvaliador(nome) {
  const texto = (nome || '').toString().trim().replace(/\s+/g, ' ');
  if (!texto) return '';

  const partes = texto.split(' ');
  if (partes.length <= 2) return texto;

  return partes.slice(0, 2).join(' ');
}
