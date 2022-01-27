import Foundation

@propertyWrapper
struct UserDefaultSetting<Value> {
    var wrappedValue: Value {
        get {
            let storedValue = UserDefaults.standard.value(forKey: key) as? Value
            return storedValue ?? defaultValue
        }
        set {
            if let optional = newValue as? AnyOptional, optional.isNil {
                UserDefaults.standard.removeObject(forKey: key)
            } else {
                UserDefaults.standard.set(newValue, forKey: key)
            }
            UserDefaults.standard.synchronize()
        }
    }
    var defaultValue: Value
    let key: String

    init(wrappedValue defaultValue: Value, _ key: String) {
        self.defaultValue = defaultValue
        self.key = key
    }
}

private protocol AnyOptional {
    var isNil: Bool { get }
}

extension Optional: AnyOptional {
    var isNil: Bool { self == nil }
}