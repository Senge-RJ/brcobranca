module Brcobranca
	module Boleto
		class CaixaSindical < Caixa
			define_template(:rghost_sindical_empresa).each do |klass|
				extend klass
				include klass
			end
			
			# Aviso essas regras estão fixas para para sindical !!!
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
				File.join(File.dirname(__FILE__), '..', 'arquivos', 'logos', 'caixa.eps')
			end
		end
	end
end