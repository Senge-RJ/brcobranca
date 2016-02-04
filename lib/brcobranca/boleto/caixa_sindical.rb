module Brcobranca
	module Boleto
		class CaixaSindical < Caixa
			# Aviso essas regras estão fixas para para sindical !!!

			# Monta a segunda parte do código de barras.
			#  1 à 6: código do cedente, também conhecido como convênio
			#  7: dígito verificador do código do cedente
			#  8 à 10: dígito 3 à 5 do nosso número
			#  11: dígito 1 do nosso número (modalidade da cobrança)
			#  12 à 14: dígito 6 à 8 do nosso número
			#  15: dígito 2 do nosso número (emissão do boleto)
			#  16 à 24: dígito 9 à 17 do nosso número
			#  25: dígito verificador do campo livre
			# @return [String]
			def codigo_barras_segunda_parte
				campo_livre = '97' \
				"#{documento_cedente_sicas[8, 5]}" \
				'7' \
				'1' \
				'77' \
				"#{numero_documento[3, 12]}" \
				'42'
				"#{campo_livre}"
			end

			# Forçar logo da caixa
			def logotipo
				if Brcobranca.configuration.gerador == :rghost_carne
					File.join(File.dirname(__FILE__), '..', 'arquivos', 'logos', 'caixa_carne.eps')
				else
					File.join(File.dirname(__FILE__), '..', 'arquivos', 'logos', 'caixa.eps')
				end
			end
		end
	end
end