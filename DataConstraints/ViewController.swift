//
//  ViewController.swift
//  DataConstraints
//
//  Created by Alexei Shepitko on 30/08/2018.
//  Copyright © 2018 Alexei Shepitko. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!

    var users: [User] = []

    lazy var viewContext: NSManagedObjectContext = {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            fatalError()
        }
        let context = appDelegate.persistentContainer.viewContext
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        fetchAndOutputData()
    }

    @IBAction func refresh(_ sender: Any) {
        let privateContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        privateContext.parent = viewContext
        privateContext.perform { [weak self] in
            guard let strongSelf = self else {
                return
            }
            (1...5).forEach { index in
                let user = User(context: privateContext)
                user.id = Int64(index)
                user.firstName = "John"
                user.lastName = "Doe"
                user.updatedAt = Date()
            }
            do {
                try privateContext.save()
                strongSelf.viewContext.performAndWait {
                    do {
                        try strongSelf.viewContext.save()
                    } catch {
                        fatalError("Failure to save context: \(error)")
                    }
                }
                DispatchQueue.main.async {
                    strongSelf.fetchAndOutputData()
                }
            } catch {
                fatalError("Failure to save context: \(error)")
            }
        }
    }

    fileprivate func fetchAndOutputData() {
        let request = NSFetchRequest<User>(entityName: "User")
        request.sortDescriptors = [ NSSortDescriptor(key: "id", ascending: true) ]
        if let users = try? viewContext.fetch(request) {
            self.users = users
        }
        else {
            users = []
        }
        tableView.reloadData()
    }

}

extension ViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CellID")!
        let user = users[indexPath.row]
        cell.textLabel?.text = "\(user.firstName ?? "") \(user.lastName ?? "") \(user.id)"
        cell.detailTextLabel?.text = "\(user.updatedAt?.description ?? "")"
        return cell
    }


}
