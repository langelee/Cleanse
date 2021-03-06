//
//  RepositoriesPage.swift
//  CleanseGithubBrowser
//
//  Created by Mike Lewis on 6/11/16.
//  Copyright © 2016 Square, Inc. All rights reserved.
//

import Foundation
import UIKit
import Cleanse


/// A module that configures a tab page on the root view controller as well as on the settings page
struct RepositoriesModule : Cleanse.Module {
    func configure<B : Binder>(binder binder: B) {
        // Make RepositoriesViewController available to be injected
        binder
            .bind()
            .to(factory: RepositoriesViewController.init)

        // Make RepositoriesSettingsSplitViewController available to be injected
        binder
            .bind()
            .to(factory: RepositoriesSettingsSplitViewController.init)

        // Add RepositoriesViewController to the root view controller's tab bar
        binder
            .bind(RootTabBarItem.self)
            .intoCollection()
            .to { (repositoriesViewController: RepositoriesViewController) -> RootTabBarItem in
                let navController = UINavigationController(rootViewController: repositoriesViewController)
                return RootTabBarItem(viewController: navController, rank: 0)
            }


        // Make the RepositoriesPageSettings available as a singleton. This is a shared object
        binder
            .bind()
            .asSingleton()
            .to(factory: RepositoriesPageSettings.init)

        // Make the ShowWatcherCountCell available for injection
        binder
            .bind()
            .to(factory: ShowWatcherCountCell.init)

        // Add "Repositories Settings" to the settings view controller
        binder
            .bind(SettingsItem.self)
            .intoCollection()
            .to {
                SettingsItem(
                    title: "Repositories",
                    viewControllerProvider: ($0 as Provider<RepositoriesSettingsSplitViewController>),
                    rank: 0
                )
            }
    }
}

/// View controller that shows a list of repositories for the configured github organization
class RepositoriesViewController : TableViewController {
    let repositoriesService: GithubRepositoriesService

    private var repositories = [GithubRepository]()

    private let settings: RepositoriesPageSettings

    init(
        repositoriesService: GithubRepositoriesService,
        githubOrganizationName: TaggedProvider<GithubOrganizationName>,
        settings: RepositoriesPageSettings
    ) {
        self.repositoriesService = repositoriesService
        self.settings = settings

        super.init()

        self.title = "Repositories"
        self.navigationItem.title = "Repositories for \(githubOrganizationName.get())"

        self.tabBarItem.image = UIImage(
            named: "TabBarIcons/Repositories",
            inBundle: NSBundle(forClass: self.dynamicType),
            compatibleWithTraitCollection: nil
        )
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return repositories.count
    }

    override func tableView(
        tableView: UITableView,
        cellForRowAtIndexPath indexPath: NSIndexPath
    ) -> UITableViewCell {
        let identifier = settings.showWatcherCount ? "Cell1" : "Cell2"
        let style: UITableViewCellStyle = settings.showWatcherCount ? .Subtitle : .Default

        let cell = tableView.dequeueReusableCellWithIdentifier(identifier)
            ?? UITableViewCell(style: style, reuseIdentifier: identifier)

        let repository = repositories[indexPath.row]

        cell.textLabel?.text = repository.name

        if settings.showWatcherCount {
            cell.detailTextLabel?.text = "\(repository.watchersCount) watchers"
        }

        cell.selectionStyle = .None
        
        return cell
    }


    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        refresh()
    }

    func refresh() {
        repositoriesService.list { [weak self] result in
            guard let `self` = self else {
                return
            }

            do {
                self.repositories = try result.get()
                self.tableView.reloadData()
            } catch let e  {
                NSLog("We got an error \(e) fetching repositories. Doing nothing")
                return
            }
        }
    }
}


/// This is a singleton that controls how the members page is displayed
class RepositoriesPageSettings {
    // If true, we show the number of watchers
    var showWatcherCount = true
}

class RepositoriesSettingsSplitViewController : TableViewController {

    private let cells: [UITableViewCell]

    init(showWatcherCount: ShowWatcherCountCell) {

        self.cells = [showWatcherCount]

        super.init()

        self.title = "Repositories Settings"
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cells.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        return cells[indexPath.row]
    }
}

class ShowWatcherCountCell : UITableViewCell {
    let `switch` = UISwitch()
    let settings: RepositoriesPageSettings

    init(settings: RepositoriesPageSettings) {
        self.settings = settings

        super.init(style: .Default, reuseIdentifier: nil)

        `switch`.on = settings.showWatcherCount

        `switch`.addTarget(self, action: #selector(valueChanged), forControlEvents: .TouchUpInside)

        textLabel?.text = "Show Watcher Count"

        accessoryView = `switch`
        selectionStyle = .None
    }

    @objc private func valueChanged() {
        self.settings.showWatcherCount = `switch`.on
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


