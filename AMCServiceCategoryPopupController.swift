//
//  AMCServiceCategoryPopupController.swift
//  ClaudiaSalon
//
//  Created by Keith Staines on 10/02/2016.
//  Copyright © 2016 ClaudiasSalon. All rights reserved.
//

import Cocoa


class AMCServiceCategoryPopupController : NSObject, NSTableViewDelegate, NSTableViewDataSource {
    @IBOutlet weak var popupButton: NSPopUpButton!
    @IBOutlet weak var servicesTable: NSTableView? {
        didSet {
            if self.servicesTable != nil {
                self.servicesTable!.setDelegate(self)
                self.servicesTable!.setDataSource(self)
            }
        }
    }
    var rootServiceCategory:ServiceCategory!
    var servicesTableLabel: NSTextView?
    var hasSelection: Bool {
        return (self.selectedCategory != nil)
    }
    private var services = [Service]()
    
    var selectedCategory:ServiceCategory? {
        didSet {
            willChangeValueForKey("hasSelection")
            self.services.removeAll()
            guard let category = self.selectedCategory else {
                return
            }
            let serviceSet = self.allServicesUnderCategory(category)
            self.services = Array(serviceSet).sort({ (service1, service2) -> Bool in
                return (service1.name?.capitalizedString < service2.name?.capitalizedString)
            })
            self.servicesTable?.reloadData()
        }
    }
    
    func allServicesUnderCategory(category:ServiceCategory) -> Set<Service> {
        var allServicesSet = Set<Service>()
        if let service = category.service {
            allServicesSet.unionInPlace(service)
        }
        if let subCategories = category.subCategories {
            for subCategory in subCategories {
                allServicesSet.unionInPlace(self.allServicesUnderCategory(subCategory))
            }
        }
        return allServicesSet
    }
    override init() {
        super.init()
    }
    convenience init(rootServiceCategory:ServiceCategory,popupButton:NSPopUpButton,servicesTable:NSTableView?, servicesTableLabel:NSTextView?) {
        self.init()
        self.popupButton = popupButton
        self.rootServiceCategory = rootServiceCategory
        self.servicesTable = servicesTable
        self.refreshListWithRootCategory(self.rootServiceCategory)
    }
    func refresh() {
        self.refreshListWithRootCategory(self.rootServiceCategory)
    }
    func refreshListWithRootCategory(rootServiceCategory:ServiceCategory) {
        self.rootServiceCategory = rootServiceCategory
        self.popupButton.removeAllItems()
        self.popupButton.addItemWithTitle("All Service Categories")
        self.popupButton.autoenablesItems = false
        for subCategory in self.rootServiceCategory.subCategories! {
            self.popupButton.menu?.addItem(menuItemFromCategory(subCategory))
        }
        self.selectedCategory = rootServiceCategory
    }
    
    private func menuItemFromCategory(serviceCategory:ServiceCategory)->NSMenuItem {
        let menuItem = NSMenuItem(title: serviceCategory.name ?? "Unknown category name", action: Selector("categoryPopupChanged:"), keyEquivalent: "")
        menuItem.target = self
        menuItem.representedObject = serviceCategory
        if serviceCategory.subCategories!.count > 0 {
            menuItem.submenu = NSMenu()
            menuItem.submenu?.autoenablesItems = false
            let subCategorySet = serviceCategory.subCategories!
            let subCategoryArray = Array(subCategorySet).sort({ (category1, category2) -> Bool in
                return (category1.name?.lowercaseString < category2.name?.lowercaseString)
            })
            for subCategory in subCategoryArray {
                menuItem.submenu?.addItem(self.menuItemFromCategory(subCategory))
            }
        }
        return menuItem
    }
    func categoryPopupChanged(sender:NSMenuItem) {
        guard let serviceCategory = sender.representedObject as! ServiceCategory? else {
            self.selectedCategory = nil
            return
        }
        if self.selectedCategory === serviceCategory {
            return
        }
        self.selectedCategory = serviceCategory
    }
 
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return services.count
    }
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        switch tableView {
        case self.servicesTable!:
            guard let _ = tableColumn?.identifier else {
                return nil
            }
            let service = self.services[row]
            let view = tableView.makeViewWithIdentifier("serviceView", owner: self) as! NSTableCellView
            view.textField?.stringValue = service.displayText()
            return view
        default:
            return nil
        }
    }
}

