-- =====================================================
-- CORREÇÃO: ADICIONAR CAMPO IDADE NA TABELA JOVENS
-- =====================================================

-- Adicionar campo idade se não existir
do $$
begin
  if not exists (select 1 from information_schema.columns where table_name = 'jovens' and column_name = 'idade') then
    alter table jovens add column idade int;
    raise notice 'Campo idade adicionado à tabela jovens';
  else
    raise notice 'Campo idade já existe na tabela jovens';
  end if;
end $$;

-- Atualizar idade para todos os jovens existentes
update jovens 
set idade = date_part('year', age(data_nasc))::int
where idade is null;

-- Verificar se o campo foi adicionado e os dados foram atualizados
select 
  count(*) as total_jovens,
  count(idade) as jovens_com_idade,
  avg(idade) as idade_media
from jovens;

-- Testar o trigger com um novo registro
insert into jovens (nome_completo, data_nasc, estado_id, edicao, edicao_id) 
values ('Teste Idade', '1990-01-01', (select id from estados limit 1), '3ª Edição', (select id from edicoes where ativa = true limit 1));

-- Verificar se a idade foi calculada automaticamente
select nome_completo, data_nasc, idade from jovens where nome_completo = 'Teste Idade';

-- Limpar dados de teste
delete from jovens where nome_completo = 'Teste Idade';
