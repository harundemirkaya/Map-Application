//
//  ListViewController.swift
//  MapApp
//
//  Created by Harun Demirkaya on 24.12.2022.
//

import UIKit
import CoreData

class ListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    var locations = [LocationModel]()
    var selectedID: UUID?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        
        navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.add, target: self, action: #selector(addButton))
        
        fetchData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(fetchData), name: NSNotification.Name?(NSNotification.Name(rawValue: "saved")), object: nil)
    }
    
    @objc func fetchData(){
        locations.removeAll(keepingCapacity: false)
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Location")
        request.returnsObjectsAsFaults = false
        
        do{
            let results = try context.fetch(request)
            if results.count > 0{
                for result in results as! [NSManagedObject]{
                    if let title = result.value(forKey: "title") as? String, let id = result.value(forKey: "id") as? UUID{
                        let location = LocationModel(id: id, title: title)
                        locations.append(location)
                    }
                }
            }
            tableView.reloadData()
        } catch{
            print("Error")
        }
    }
    
    @objc func addButton(){
        performSegue(withIdentifier: "toMapVC", sender: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return locations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = locations[indexPath.row].title
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedID = locations[indexPath.row].id
        performSegue(withIdentifier: "toMapVC", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toMapVC"{
            let destination = segue.destination as! MapViewController
            destination.selectID = selectedID
        }
    }
    
    
}
