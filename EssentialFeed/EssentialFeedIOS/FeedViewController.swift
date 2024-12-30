//
//  FeedViewController.swift
//  EssentialFeedIOS
//
//  Created by Anh Nguyen on 30/12/2024.
//

import EssentialFeed
import UIKit

public final class FeedViewController: UITableViewController {
    private var loader: FeedLoader!
    private var makeRefreshControl: (() -> UIRefreshControl)!
    
    public convenience init(loader: FeedLoader, makeRefreshControl: @escaping (() -> UIRefreshControl) = UIRefreshControl.init) {
        self.init()
        self.loader = loader
        self.makeRefreshControl = makeRefreshControl
    }
    
    deinit {
        loader = nil
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshControl = makeRefreshControl()
        refreshControl?.addTarget(self, action: #selector(load), for: .valueChanged)
        load()
    }
    
    @objc private func load() {
        refreshControl?.beginRefreshing()
        loader.load { [weak self] _ in
            self?.refreshControl?.endRefreshing()
        }
    }
}
