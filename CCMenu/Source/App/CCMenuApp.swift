/*
 *  Copyright (c) Erik Doernenburg and contributors
 *  Licensed under the Apache License, Version 2.0 (the "License"); you may
 *  not use these files except in compliance with the License.
 */

import SwiftUI


@main
struct CCMenuApp: App {

    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    private var pipelineModel: PipelineModel
    private var serverMonitor: ServerMonitor
    private var notificationSender: NotificationSender

    init() {
        registerAWSCodePipelineProvider()
        pipelineModel = PipelineModel()
        serverMonitor = ServerMonitor(model: pipelineModel)
        notificationSender = NotificationSender(model: pipelineModel)

        if UserDefaults.standard.bool(forKey: "ignoreDefaults") {
            print("Ignoring user defaults from system.")
            UserDefaults.active = UserDefaults.transient
        }

        if let filename = UserDefaults.standard.string(forKey: "loadPipelines") {
            print("Loading pipeline definitions from file \(filename).")
            pipelineModel.loadPipelinesFromFile(filename)
        } else {
            pipelineModel.loadPipelinesFromUserDefaults()
        }

        if UserDefaults.standard.bool(forKey: "pauseMonitor") {
            print("Pausing monitor.")
        } else {
            serverMonitor.start()
        }

        notificationSender.start()
    }

    var body: some Scene {

        Window("Pipelines", id:"pipeline-list") {
            PipelineListView(model: pipelineModel)
        }
        .defaultSize(width: 550, height: 600)
        .keyboardShortcut("0", modifiers: [ .command ])
        Settings {
            SettingsView()
        }
        MenuBarExtra() {
            MenuBarExtraMenu(model: pipelineModel)
        } label: {
            MenuBarExtraLabel(model: pipelineModel)
        }

    }

}
