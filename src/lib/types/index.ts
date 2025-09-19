// Database Types
export interface Estado {
  id: string;
  nome: string;
  sigla: string;
}

export interface Bloco {
  id: string;
  estado_id: string;
  nome: string;
  estado?: Estado;
}

export interface Regiao {
  id: string;
  bloco_id: string;
  nome: string;
  bloco?: Bloco;
}

export interface Igreja {
  id: string;
  regiao_id: string;
  nome: string;
  endereco?: string;
  regiao?: Regiao;
}

export interface Edicao {
  id: string;
  numero: number;
  nome: string;
  data_inicio?: string;
  data_fim?: string;
  ativa: boolean;
  criado_em: string;
}

export interface Role {
  id: string;
  slug: string;
  nome: string;
  descricao?: string;
  nivel_hierarquico: number;
  criado_em: string;
}

export interface UserRole {
  id: string;
  user_id: string;
  role_id: string;
  estado_id?: string;
  bloco_id?: string;
  regiao_id?: string;
  igreja_id?: string;
  ativo: boolean;
  criado_em: string;
  criado_por: string;
  role?: Role;
}

export interface Usuario {
  id: string;
  id_auth: string;
  email?: string;
  foto?: string;
  nome: string;
  sexo: 'masculino' | 'feminino';
  nivel: string;
  estado_bandeira?: string;
  estado_id?: string;
  bloco_id?: string;
  regiao_id?: string;
  igreja_id?: string;
  ativo: boolean;
  criado_em: string;
  user_roles?: UserRole[];
}

export interface Jovem {
  id: string;
  estado_id?: string;
  bloco_id?: string;
  regiao_id?: string;
  igreja_id?: string;
  edicao: string;
  edicao_id?: string;
  foto?: string;
  nome_completo: string;
  viagem?: Viagem | null;
  whatsapp?: string;
  data_nasc: string;
  idade?: number;
  data_cadastro: string;
  estado_civil?: string;
  namora?: boolean;
  tem_filho?: boolean;
  trabalha?: boolean;
  local_trabalho?: string;
  escolaridade?: string;
  formacao?: string;
  tem_dividas?: boolean;
  valor_divida?: number;
  tempo_igreja?: string;
  batizado_aguas?: boolean;
  data_batismo_aguas?: string;
  batizado_es?: boolean;
  data_batismo_es?: string;
  condicao?: string;
  tempo_condicao?: string;
  responsabilidade_igreja?: string;
  disposto_servir?: boolean;
  ja_obra_altar?: boolean;
  ja_obreiro?: boolean;
  ja_colaborador?: boolean;
  afastado?: boolean;
  data_afastamento?: string;
  motivo_afastamento?: string;
  data_retorno?: string;
  pais_na_igreja?: boolean;
  observacao_pais?: string;
  familiares_igreja?: boolean;
  deseja_altar?: boolean;
  observacao?: string;
  testemunho?: string;
  instagram?: string;
  facebook?: string;
  tiktok?: string;
  observacao_redes?: string;
  pastor_que_indicou?: string;
  cresceu_na_igreja?: boolean;
  experiencia_altar?: boolean;
  foi_obreiro?: boolean;
  foi_colaborador?: boolean;
  afastou?: boolean;
  quando_afastou?: string;
  motivo_afastou?: string;
  quando_voltou?: string;
  pais_sao_igreja?: boolean;
  obs_pais?: string;
  familiares_igreja?: boolean;
  deseja_altar?: boolean;
  observacao_text?: string;
  testemunho_text?: string;
  instagram?: string;
  facebook?: string;
  tiktok?: string;
  observacao_redes?: string;
  formado_intellimen?: boolean;
  fazendo_desafios?: boolean;
  qual_desafio?: string;
  aprovado: 'null' | 'pre_aprovado' | 'aprovado';
  // Relations
  estado?: Estado;
  bloco?: Bloco;
  regiao?: Regiao;
  igreja?: Igreja;
  edicao_obj?: Edicao;
}

export interface Avaliacao {
  id: string;
  jovem_id: string;
  user_id: string;
  espirito?: 'ruim' | 'ser_observar' | 'bom' | 'excelente';
  caractere?: 'excelente' | 'bom' | 'ser_observar' | 'ruim';
  disposicao?: 'muito_disposto' | 'normal' | 'pacato' | 'desanimado';
  avaliacao_texto?: string;
  nota?: number;
  data?: string;
  criado_em: string;
  // Relations
  jovem?: Jovem;
  avaliador?: Usuario;
}

// Viagens
export interface Viagem {
  id: string;
  jovem_id: string;
  edicao_id: string;
  pagou_despesas: boolean;
  comprovante_pagamento?: string;
  data_passagem_ida?: string; // ISO string (timestamptz)
  comprovante_passagem_ida?: string;
  data_passagem_volta?: string; // ISO string (timestamptz)
  comprovante_passagem_volta?: string;
  data_cadastro: string;
  atualizado_em?: string;
}

export interface JovemComViagem extends Jovem {
  viagem?: Viagem | null;
}

export interface LogHistorico {
  id: string;
  jovem_id: string;
  user_id: string;
  acao: string;
  detalhe?: string;
  dados_anteriores?: any;
  dados_novos?: any;
  created_at: string;
  // Relations
  jovem?: Jovem;
  usuario?: Usuario;
}

// UI Types
export interface FilterOptions {
  edicao: string;
  condicao: string;
  sexo: string;
  idade_min: string;
  idade_max: string;
  estado_id: string;
  bloco_id: string;
  regiao_id: string;
  igreja_id: string;
  aprovado: string;
  nome_like: string;
}

export interface Pagination {
  page: number;
  limit: number;
  total: number;
  totalPages: number;
}

export interface SelectOption {
  value: string;
  label: string;
}

// Form Types
export interface JovemFormData {
  nome_completo: string;
  whatsapp?: string;
  data_nasc: string;
  sexo?: 'masculino' | 'feminino';
  estado_civil?: string;
  namora?: boolean;
  tem_filho?: boolean;
  trabalha?: boolean;
  local_trabalho?: string;
  escolaridade?: string;
  formacao?: string;
  tem_dividas?: boolean;
  valor_divida?: number;
  tempo_igreja?: string;
  batizado_aguas?: boolean;
  data_batismo_aguas?: string;
  batizado_es?: boolean;
  data_batismo_es?: string;
  condicao?: string;
  tempo_condicao?: string;
  responsabilidade_igreja?: string;
  disposto_servir?: boolean;
  ja_obra_altar?: boolean;
  ja_obreiro?: boolean;
  ja_colaborador?: boolean;
  afastado?: boolean;
  data_afastamento?: string;
  motivo_afastamento?: string;
  data_retorno?: string;
  pais_na_igreja?: boolean;
  observacao_pais?: string;
  familiares_igreja?: boolean;
  deseja_altar?: boolean;
  observacao?: string;
  testemunho?: string;
  instagram?: string;
  facebook?: string;
  tiktok?: string;
  observacao_redes?: string;
  pastor_que_indicou?: string;
  cresceu_na_igreja?: boolean;
  experiencia_altar?: boolean;
  foi_obreiro?: boolean;
  foi_colaborador?: boolean;
  afastou?: boolean;
  quando_afastou?: string;
  motivo_afastou?: string;
  quando_voltou?: string;
  pais_sao_igreja?: boolean;
  obs_pais?: string;
  familiares_igreja?: boolean;
  deseja_altar?: boolean;
  observacao_text?: string;
  testemunho_text?: string;
  instagram?: string;
  facebook?: string;
  tiktok?: string;
  observacao_redes?: string;
  formado_intellimen?: boolean;
  fazendo_desafios?: boolean;
  qual_desafio?: string;
  estado_id?: string;
  bloco_id?: string;
  regiao_id?: string;
  igreja_id?: string;
  edicao_id?: string;
  aprovado?: 'null' | 'pre_aprovado' | 'aprovado';
}
