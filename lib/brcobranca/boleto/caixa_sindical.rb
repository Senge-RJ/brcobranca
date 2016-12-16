module Brcobranca
	module Boleto
		class CaixaSindical < Caixa
			define_template(:rghost_sindical_empresa).each do |klass|
				extend klass
				include klass
			end

			# Aviso essas regras estão fixas para para sindical !!!
			def codigo_barras_segunda_parte
				codigo_beneficiario = "775800"
				dv_beneficiario 		= codigo_beneficiario.modulo11(
					multiplicador: (2..9).to_a,
					mapeamento: { 10 => 0, 11 => 0 }
				) { |t| 11 - (t % 11) }
				sequencia_1					= numero_documento[0, 3]
				constante_1 				= 1 # Tipo de cobranca (1 - Registrada)
				sequencia_2					= numero_documento[3, 3]
				constante_2 				= 4 # Identificador de Emissao do Boleto (4-Beneficiario)
				sequencia_3					= numero_documento[6, 9]

				campo_livre = "#{codigo_beneficiario}#{dv_beneficiario}" \
											"#{sequencia_1}#{constante_1}" \
											"#{sequencia_2}#{constante_2}#{sequencia_3}"

				dv_campo_livre = campo_livre.modulo11(
					multiplicador: (2..9).to_a,
					mapeamento: { 10 => 0, 11 => 0 }
				) { |t| 11 - (t % 11) }

				"#{campo_livre}#{dv_campo_livre}"
			end

			# Forçar logo da caixa
			def logotipo
				File.join(File.dirname(__FILE__), '..', 'arquivos', 'logos', 'caixa.eps')
			end
		end
	end
end
