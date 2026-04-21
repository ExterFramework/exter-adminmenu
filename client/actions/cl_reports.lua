-- [ Code ] --

-- [ Events ] --

RegisterNetEvent("exter-adminmenu/client/send-report", function(ReportData)
    if not HasReport() then
        QBCore.Functions.Notify(Lang:t('info.report_sent'), 'success')
        Config.Reports[#Config.Reports + 1] = ReportData
        TriggerServerEvent('exter-adminmenu/server/sync-chat-data', 'Reports', Config.Reports, 1500)
        ToggleMenu(true)
    else
        QBCore.Functions.Notify(Lang:t('info.report_already', { chatcommand = Config.Commands['ReportChat'], chatcommandclose = Config.Commands['ReportClose'] }), 'error')
    end
end)

RegisterNetEvent("exter-adminmenu/client/close-report", function()
    if HasReport() then
        local ReportId = GetPlayerReportFromName()
        if ReportId then
            local Success, ServerId = DeleteReport(Config.Reports[ReportId]['Id'])
            if Success then
                QBCore.Functions.Notify(Lang:t('info.report_closed_self'), 'success')
            end
        end
    else
        QBCore.Functions.Notify(Lang:t('info.report_not', { chatcommand = Config.Commands['ReportNew'] }), 'error')
    end
end)

RegisterNetEvent("exter-adminmenu/client/reply-report", function(Message, Time)
    if HasReport() then
        local ReportId = GetPlayerReportFromName()
        if ReportId then
            local Success = AddReportMessage(Config.Reports[ReportId]['Id'], Message, Time)
            if Success then
                QBCore.Functions.Notify(Lang:t('info.report_reply_success'), 'success')
            else
                QBCore.Functions.Notify(Lang:t('info.report_reply_error'), 'error')
            end
        end
    else
        QBCore.Functions.Notify(Lang:t('info.report_not', { chatcommand = Config.Commands['ReportNew'] }), 'error')
    end
end)

RegisterNetEvent('exter-adminmenu/client/sync-chat-data', function(Type, Data, UpdateDelay)
    if not IsPlayerAdmin() then return end
    if Type == 'Staffchat' then Config.StaffChat = Data else Config.Reports = Data end
    if UpdateDelay then
        SetTimeout(UpdateDelay, function()
            SendNUIMessage({
                Action = 'UpdateChats',
                Staffchat = Type == 'Staffchat' and Config.StaffChat or false,
                Reports = Type == 'Reports' and Config.Reports or false,
            })
        end)
    else
        SendNUIMessage({
            Action = 'UpdateChats',
            Staffchat = Type == 'Staffchat' and Config.StaffChat or false,
            Reports = Type == 'Reports' and Config.Reports or false,
        })
    end
end)