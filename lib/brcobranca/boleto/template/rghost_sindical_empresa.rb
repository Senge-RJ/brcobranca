# -*- encoding: utf-8 -*-

begin
  require 'rghost'
rescue LoadError
  require 'rubygems' unless ENV['NO_RUBYGEMS']
  gem 'rghost'
  require 'rghost'
end

begin
  require 'rghost_barcode'
rescue LoadError
  require 'rubygems' unless ENV['NO_RUBYGEMS']
  gem 'rghost_barcode'
  require 'rghost_barcode'
end

module Brcobranca
  module Boleto
    module Template
      # Templates para usar com Rghost
      module RghostSindicalEmpresa
        extend self
        include RGhost unless self.include?(RGhost)
        RGhost::Config::GS[:external_encoding] = Brcobranca.configuration.external_encoding

        # Gera o boleto em usando o formato desejado [:pdf, :jpg, :tif, :png, :ps, :laserjet, ... etc]
        #
        # @return [Stream]
        # @see http://wiki.github.com/shairontoledo/rghost/supported-devices-drivers-and-formats Veja mais formatos na documentação do rghost.
        # @see Rghost#modelo_generico Recebe os mesmos parâmetros do Rghost#modelo_generico.
        def to(formato, options = {})
          modelo_guia_caixa(self, options.merge!(formato: formato))
        end

        # Gera o boleto em usando o formato desejado [:pdf, :jpg, :tif, :png, :ps, :laserjet, ... etc]
        #
        # @return [Stream]
        # @see http://wiki.github.com/shairontoledo/rghost/supported-devices-drivers-and-formats Veja mais formatos na documentação do rghost.
        # @see Rghost#modelo_generico Recebe os mesmos parâmetros do Rghost#modelo_generico.
        def lote(boletos, options = {})
          modelo_generico_multipage(boletos, options)
        end

        #  Cria o métodos dinâmicos (to_pdf, to_gif e etc) com todos os fomátos válidos.
        #
        # @return [Stream]
        # @see Rghost#modelo_generico Recebe os mesmos parâmetros do Rghost#modelo_generico.
        # @example
        #  @boleto.to_pdf #=> boleto gerado no formato pdf
        def method_missing(m, *args)
          method = m.to_s
          if method.start_with?('to_')
            modelo_guia_caixa(self, (args.first || {}).merge!(formato: method[3..-1]))
          else
            super
          end
        end

        private

        # Layout Guia Caixa Economica - Senge --------------------------------------------------------------------------------------

        def modelo_guia_caixa(boleto, options = {})
          doc = Document.new paper: :A4 # 210x297

          template_path = File.join(File.dirname(__FILE__), '..', '..', 'arquivos', 'templates', 'modelo_sindical_empresa.eps')

          modelo_guia_sindical_empresa_template(doc, boleto, template_path)
          modelo_guia_sindical_empresa_cabecalho(doc, boleto)
          modelo_guia_sindical_empresa_rodape(doc, boleto)

          # Gerando codigo de barra com rghost_barcode
          doc.barcode_interleaved2of5(boleto.codigo_barras, width: '10.3 cm', height: '1.3 cm', x: '1.6 cm', y: '0.1 cm') if boleto.codigo_barras

          # Gerando stream
          formato = (options.delete(:formato) || Brcobranca.configuration.formato)
          resolucao = (options.delete(:resolucao) || Brcobranca.configuration.resolucao)
          doc.render_stream(formato.to_sym, resolution: resolucao)
        end

        # Define o template a ser usado no boleto
        def modelo_guia_sindical_empresa_template(doc, _boleto, template_path)
          doc.define_template(:template, template_path, x: '0.3 cm', y: '0 cm')
          doc.use_template :template

          doc.define_tags do
            tag :grande, size: 13
            tag :media, size: 11
            tag :pequena, size: 7
          end
        end

        # Monta o cabeçalho do layout do boleto
        def modelo_guia_sindical_empresa_cabecalho(doc, boleto)
          # INICIO Primeira parte do BOLETO

          # Cedente - Beneficiario

          # Logo do Banco
          doc.image(boleto.logotipo, x: '2.10 cm', y: '30.00 cm', zoom: 100)

          # Numero do banco e DV
          doc.moveto x: '1.3 cm', y: '12.65 cm'
          doc.show "#{boleto.banco}-#{boleto.banco_dv}", tag: :grande

          # Linha digital
          doc.moveto x: '3.7 cm', y: '12.65 cm'
          doc.show boleto.codigo_barras.linha_digitavel, tag: :grande

          # Codigo da Entidade Sindica (Código de Cedente)
          doc.moveto x: '1 cm', y: '11.9 cm'
          doc.show boleto.documento_cedente_sicas

          # Nosso numero
          doc.moveto x: '4 cm', y: '11.9 cm'
          doc.show boleto.numero_documento.to_i.to_s

          #  Valor do Documento  - Sacador
          doc.moveto x: '9 cm', y: '11.9 cm'
          doc.show boleto.valor

          # Data de Vencimento
          doc.moveto x: '12 cm', y: '11.9 cm'
          doc.show boleto.data_vencimento.to_s_br

          # Ano de exercicio
          doc.moveto x: '16 cm', y: '11.9 cm'
          doc.show boleto.exercicio

          # Cendete
          doc.moveto x: '3 cm', y: '22.3 cm'
          doc.show boleto.cedente

          # Data de Vencimento
          doc.moveto x: '15.4 cm', y: '23.1 cm'
          doc.show boleto.data_vencimento.to_s_br

          # Ano de exercicio
          doc.moveto x: '17.6 cm', y: '23.1 cm'
          doc.show boleto.exercicio

          # Codigo da Entidade Sindica
          doc.moveto x: '15.6 cm', y: '22.2 cm'
          doc.show boleto.documento_cedente_sicas

          # Endereco
          doc.moveto x: '2.9 cm', y: '21.7 cm'
          doc.show boleto.cedente_endereco_log

          # Numero
          doc.moveto x: '8.9 cm', y: '21.7 cm'
          doc.show boleto.cedente_endereco_num

          # Complemento
          doc.moveto x: '12.9 cm', y: '21.6 cm'
          doc.show boleto.cedente_endereco_compl

          # Documento Cendete - CNPJ
          doc.moveto x: '14.9 cm', y: '21.6 cm'
          doc.show boleto.documento_cedente

          # Bairro
          doc.moveto x: '2 cm', y: '21 cm'
          doc.show boleto.cedente_endereco_bairro

          # CEP
          doc.moveto x: '5 cm', y: '21 cm'
          doc.show boleto.cedente_endereco_cep

          # Cidade/Municipio
          doc.moveto x: '14 cm', y: '21 cm'
          doc.show boleto.cedente_endereco_cidade

          # UF
          doc.moveto x: '17 cm', y: '21 cm'
          doc.show boleto.cedente_endereco_uf

          # Sacado - Pagador

          #  Nome sacador
          doc.moveto x: '1 cm', y: '19.8 cm'
          doc.show boleto.sacado

          #  Documento sacador
          doc.moveto x: '15 cm', y: '19.8 cm'
          doc.show boleto.sacado_documento

          #  Endereço Sacador
          doc.moveto x: '1 cm', y: '19.2 cm'
          doc.show boleto.sacado_endereco_log

          #  Numero do Endereço - Sacador
          doc.moveto x: '8.2 cm', y: '19.2 cm'
          doc.show boleto.sacado_endereco_num

          #  Complemento do Endereço - Sacador
          doc.moveto x: '12.2 cm', y: '19.2 cm'
          doc.show boleto.sacado_endereco_compl

          #  CEP do Endereço - Sacador
          doc.moveto x: '1 cm', y: '18.5 cm'
          doc.show boleto.sacado_endereco_cep

          #  Bairro do Endereço - Sacador
          doc.moveto x: '5 cm', y: '18.5 cm'
          doc.show boleto.sacado_endereco_bairro

          #  Cidade do  - Sacador
          doc.moveto x: '11 cm', y: '18.5 cm'
          doc.show boleto.sacado_endereco_cidade

          #  Estado  - Sacador
          doc.moveto x: '14 cm', y: '18.5 cm'
          doc.show boleto.sacado_endereco_uf

          #  Codigo Atividade  - Sacador
          doc.moveto x: '16 cm', y: '18.5 cm'
          doc.show '711'

          #  Valor do Documento  - Sacador
          doc.moveto x: '14.8 cm', y: '17.1 cm'
          doc.show number_to_currency(boleto.valor)

          #  Multa  - Sacador
          doc.moveto x: '14.8 cm', y: '14.9 cm'
          doc.show number_to_currency(boleto.mora_multa)

          #  Valor Total  - Sacador
          doc.moveto x: '14.8 cm', y: '13.5 cm'
          doc.show number_to_currency(boleto.total_valor)

          if boleto.sacado_documento.size == 14 

            doc.moveto x: '10.3 cm', y: '15.6 cm'
            doc.show number_to_currency(boleto.total_remuneracao)

            doc.moveto x: '11.3 cm', y: '14.9 cm'
            doc.show boleto.total_profissionais

            doc.moveto x: '1.8 cm', y: '15.1 cm'
            doc.show "Prezado Empregador"

            doc.moveto x: '1.8 cm', y: '14.8 cm'
            doc.show "As informações dos dados do(s) profissional(is)"

            doc.moveto x: '1.8 cm', y: '14.5 cm'
            doc.show "e do valor de cada contribuição referente a esta GRCSU são da responsabilidade"

            doc.moveto x: '1.8 cm', y: '14.2 cm'
            doc.show "EXCLUSIVA do próprio EMPREGADOR."
         

          else
            doc.moveto x: '1.8 cm', y: '15.1 cm'
            doc.show "Prezado(a) profissional,"

            doc.moveto x: '1.8 cm', y: '14.8 cm'
            doc.show "As informações dos dados do contribuinte e do"

            doc.moveto x: '1.8 cm', y: '14.5 cm'
            doc.show "valor da contribuição são da responsabilidade EXCLUSIVA do próprio profissional contribuinte."

            doc.moveto x: '1.8 cm', y: '14.2 cm'
            doc.show "SAC CAIXA: 0800 726 0101 (informações, reclamações, sugestões e elogios)."

            doc.moveto x: '1.8 cm', y: '13.9 cm'
            doc.show "Para pessoas com deficiência auditiva ou de fala: 0800 726 2492."

            doc.moveto x: '1.8 cm', y: '13.6 cm'
            doc.show  "Ouvidoria: 0800 725 7474. caixa.gov.br.*"
          end
            
        end

        # Monta o corpo e rodapé do layout do boleto
        def modelo_guia_sindical_empresa_rodape(doc, boleto)
          # Logo do Banco
          doc.image(boleto.logotipo, x: '2.10 cm', y: '30.00 cm', zoom: 100)

          # Numero do banco e DV
          doc.moveto x: '4.9 cm', y: '9 cm'
          doc.show "#{boleto.banco}-#{boleto.banco_dv}", tag: :media

          # Linha digital
          doc.moveto x: '7.2 cm', y: '9 cm'
          doc.show boleto.codigo_barras.linha_digitavel, tag: :media

          # Cendete
          doc.moveto x: '2.9 cm', y: '8 cm'
          doc.show boleto.cedente

          if boleto.sacado_documento.size == 14 
            doc.moveto x: '7.9 cm', y: '6.7 cm'
            doc.show number_to_currency(boleto.total_remuneracao)
          end

          # Data do documento
          doc.moveto x: '1 cm', y: '7.2 cm'
          doc.show "#{Date.current.to_s_br}"

          # Nosso numero
          doc.moveto x: '3.5 cm', y: '7.2 cm'
          doc.show boleto.numero_documento.to_i.to_s, tag: :pequena

          # Data do documento
          doc.moveto x: '10 cm', y: '7.2 cm'
          doc.show "#{Date.current.to_s_br}"

          # Ano de exercicio
          doc.moveto x: '1.9 cm', y: '6.7 cm'
          doc.show boleto.exercicio

          # Instruções
          doc.moveto x: '1 cm', y: '5.8 cm'
          doc.show boleto.instrucao1

          doc.moveto x: '1 cm', y: '5.4 cm'
          doc.show boleto.instrucao2

          doc.moveto x: '1 cm', y: '5 cm'
          doc.show boleto.instrucao3

          doc.moveto x: '1 cm', y: '4.6 cm'
          doc.show boleto.instrucao4

          doc.moveto x: '1 cm', y: '4.2 cm'
          doc.show boleto.instrucao5

          doc.moveto x: '1 cm', y: '3.8 cm'
          doc.show boleto.instrucao6

          # sacado

          #  Nome sacador
          doc.moveto x: '1 cm', y: '2.6 cm'
          doc.show boleto.sacado

          # Endereço completo
          doc.moveto x: '1 cm', y: '2.2 cm'
          doc.show "#{boleto.sacado_endereco_log} #{boleto.sacado_endereco_num} #{boleto.sacado_endereco_compl} #{boleto.sacado_endereco_bairro} #{boleto.sacado_endereco_cidade}  #{boleto.sacado_endereco_uf}"

          # Data de Vencimento
          doc.moveto x: '15.4 cm', y: '8.4 cm'
          doc.show boleto.data_vencimento.to_s_br

          doc.moveto x: '15.4 cm', y: '7.8 cm'
          doc.show "#{agencia}/#{conta_corrente}"

          # Nosso numero
          doc.moveto x: '15.4 cm', y: '7.3 cm'
          doc.show boleto.numero_documento.to_i.to_s

          #  Valor do Documento  - Sacador
          doc.moveto x: '15.4 cm', y: '6.7 cm'
          doc.show number_to_currency(boleto.valor)

          #  Multa  - Sacador
          doc.moveto x: '15.4 cm', y: '5 cm'
          doc.show number_to_currency(boleto.mora_multa)

          #  Valor Total  - Sacador
          doc.moveto x: '15.4 cm', y: '3.3 cm'
          doc.show number_to_currency(boleto.total_valor)
        end

        # Fim Guia Caixa -----------------------------------------------------------------------------------------------------------------
      end # Base
    end
  end
end
