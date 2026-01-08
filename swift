import Foundation

// MARK: - Model
struct Contact {
    let id: Int
    var name: String
    var phones: [(String, String)]      // (number, label)
    var email: String?                  // optional
    var tags: Set<String>               // unique tags
}

// MARK: - Storage
var list: [Contact] = []
var byId: [Int: Contact] = [:]
var usedPhones: Set<String> = []
var nextId = 1

// MARK: - Input helpers (safe)
func ask(_ p: String) -> String {
    print(p, terminator: "")
    return readLine()?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
}
func askNonEmpty(_ p: String) -> String {
    var s = ""
    repeat { s = ask(p) } while s.isEmpty
    return s
}
func askInt(_ p: String) -> Int? { Int(ask(p)) }
func normalize(_ s: String) -> String { s.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
func normalizePhone(_ s: String) -> String { s.filter { !$0.isWhitespace } }

// MARK: - CRUD helpers
func save(_ c: Contact) {
    list.append(c)
    byId[c.id] = c
}
func update(_ c: Contact) {
    byId[c.id] = c
    if let i = list.firstIndex(where: { $0.id == c.id }) {
        list[i] = c
    }
}
func printContact(_ c: Contact) {
    print("ID:\(c.id)  Name:\(c.name)  Email:\(c.email ?? "—")")
    let phonesText = c.phones.map { "\($0.0)(\($0.1))" }.joined(separator: ", ")
    print("Phones: \(phonesText.isEmpty ? "—" : phonesText)")
    let tagsText = c.tags.sorted().joined(separator: ", ")
    print("Tags: \(tagsText.isEmpty ? "—" : tagsText)")
}

// MARK: - Features
func addContact() {
    let name = askNonEmpty("Name: ")

    var phones: [(String, String)] = []
    while true {
        let raw = askNonEmpty("Phone: ")
        let phone = normalizePhone(raw)
        if usedPhones.contains(phone) { print("Already exists!"); continue }

        let labelInput = ask("Label [mobile/home/work] (enter=mobile): ")
        let label = normalize(labelInput).isEmpty ? "mobile" : normalize(labelInput)

        phones.append((phone, label))
        usedPhones.insert(phone)

        let more = normalize(ask("More phone? (y/n): "))
        if more != "y" { break }
    }

    let emailRaw = ask("Email (optional, enter=skip): ")
    let email = normalize(emailRaw).isEmpty ? nil : normalize(emailRaw)

    let tagsRaw = ask("Tags comma separated (optional): ")
    let tags = Set(
        tagsRaw.split(separator: ",")
            .map { normalize(String($0)) }
            .filter { !$0.isEmpty }
    )

    let c = Contact(id: nextId, name: name, phones: phones, email: email, tags: tags)
    nextId += 1
    save(c)
    print(" Added id \(c.id)\n")
}

func listContacts() {
    if list.isEmpty { print("No contacts.\n"); return }
    for c in list.sorted(by: { $0.name.lowercased() < $1.name.lowercased() }) {
        printContact(c)
        print("----")
    }
    print()
}

func findContacts() {
    let qRaw = askNonEmpty("Search: ")
    let q = normalize(qRaw)

    let res = list.filter { c in
        c.name.lowercased().contains(q) ||
        (c.email?.contains(q) ?? false) ||
        c.phones.contains(where: { $0.0.contains(q)  $0.1.contains(q) }) 
        c.tags.contains(where: { $0.contains(q) })
    }

    if res.isEmpty { print("No matches.\n"); return }
    for c in res {
        printContact(c)
        print("----")
    }
    print()
}

func editContact() {
    guard let id = askInt("ID: "), var c = byId[id] else { print("Not found.\n"); return }

    let newName = ask("New name (enter=keep): ")
    if !newName.isEmpty { c.name = newName }

    // FIXED email logic:
    // enter = keep, "-" = remove, otherwise = set new email
    let emailInput = ask("New email (enter=keep, '-'=remove): ")
    if emailInput == "-" {
        c.email = nil
    } else if !emailInput.isEmpty {
        c.email = normalize(emailInput)
    }

    let changePhones = normalize(ask("Change phones? (y/n): "))
    if changePhones == "y" {
        // free old phones
        c.phones.forEach { usedPhones.remove($0.0) }
        var newPhones: [(String, String)] = []
        while true {
            let raw = askNonEmpty("Phone: ")
            let phone = normalizePhone(raw)
            if usedPhones.contains(phone) { print("Already exists!"); continue }

            let labelIn = ask("Label (enter=mobile): ")
            let label = normalize(labelIn).isEmpty ? "mobile" : normalize(labelIn)

            newPhones.append((phone, label))
            usedPhones.insert(phone)

            let more = normalize(ask("More phone? (y/n): "))
            if more != "y" { break }
        }
        c.phones = newPhones
    }

    let tagsInput = ask("New tags comma (enter=keep): ")
    if !tagsInput.isEmpty {
        c.tags = Set(
            tagsInput.split(separator: ",")
                .map { normalize(String($0)) }
                .filter { !$0.isEmpty }
        )
    }

    update(c)
    print("Updated.\n")
}

func deleteContact() {
    guard let id = askInt("ID: "), let c = byId[id] else { print("Not found.\n"); return }
    c.phones.forEach { usedPhones.remove($0.0) }
    byId.removeValue(forKey: id)
    list.removeAll { $0.id == id }
    print(" Deleted.\n")
}

// MARK: - Menu
while true {
    print("""
    ===== Contact Manager =====
    1 Add   2 List   3 Find   4 Update   5 Delete   0 Exit
    """)
    switch ask("Choose: ") {
    case "1": addContact()
    case "2": listContacts()
    case "3": findContacts()
    case "4": editContact()
    case "5": deleteContact()
    case "0": exit(0)
    default: print("Wrong option.\n")
    }
}
