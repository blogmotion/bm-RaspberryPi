-- pingSondes.lua
-- Envoie une notification par email si un capteur ne donne plus de signe de vie (durée paramétrable)
-- auteur: @xhark - http://blogmotion.fr/diy/domoticz-notific…ail-capteur-pile-18798
-- date: 2021/05/10

local devicesToCheck = {
		-- liste des sondes a verifier
		-- name: insensible à la casse, seuil: en minutes
        { ['name'] = 'Temperature Salon', ['seuil'] = 30 },
        { ['name'] = 'Detecteur porte entree', ['seuil'] = 30 }
}

return {
        active = true,
        on = {
                ['timer'] = {
                        'every 6 hours'
                }
        },
		
		logging = {
			level = domoticz.LOG_INFO,
			marker = "[pingSondes]"
        },
		
        execute = function(domoticz)

                local message = "---"

                for i, deviceToCheck in pairs(devicesToCheck) do
                        local name = deviceToCheck['name']
                        local threshold = deviceToCheck['seuil']
                        local minutes = domoticz.devices(name).lastUpdate.minutesAgo
                                                
                        if (minutes ~= nil) then                            
                            if ( minutes > threshold) then
                                    message = message .. 'La sonde <strong>' .. name .. '</strong> semble morte. Aucun signe de vie durant les ' .. minutes .. ' dernières minutes.\r'
                            end
                        end
                end

                if (message ~= "---") then
                        domoticz.email('Sonde(s) morte(s) !', message, 'votre@email.com')
                        domoticz.log('Sonde(s) morte(s): ' .. message, domoticz.LOG_ERROR)
                end
        end
}