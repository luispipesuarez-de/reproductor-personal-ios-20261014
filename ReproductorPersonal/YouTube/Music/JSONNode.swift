import Foundation

/// Lectura segura de JSON arbitrario: cualquier ruta que no exista devuelve un nodo vacío en lugar de fallar.
struct JSONNode {
    let raw: Any?

    init(_ raw: Any?) { self.raw = raw }

    subscript(_ key: String) -> JSONNode { JSONNode((raw as? [String: Any])?[key]) }

    subscript(_ index: Int) -> JSONNode {
        guard let array = raw as? [Any], array.indices.contains(index) else { return JSONNode(nil) }
        return JSONNode(array[index])
    }

    var string: String? { raw as? String }
    var array: [JSONNode] { (raw as? [Any])?.map { JSONNode($0) } ?? [] }
    var exists: Bool { raw != nil && !(raw is NSNull) }

    /// Todos los valores de `key` en cualquier nivel. Las claves se recorren ordenadas para que el resultado sea determinista;
    /// el orden de las listas se conserva.
    func collect(_ key: String) -> [JSONNode] {
        var found: [JSONNode] = []
        func walk(_ value: Any?) {
            if let dictionary = value as? [String: Any] {
                for name in dictionary.keys.sorted() {
                    let child = dictionary[name]
                    if name == key { found.append(JSONNode(child)) }
                    walk(child)
                }
            } else if let list = value as? [Any] {
                for child in list { walk(child) }
            }
        }
        walk(raw)
        return found
    }

    /// Texto de una lista de *runs* de YouTube Music (`[{"text": "…"}, …]`) unido.
    var runsText: String { array.compactMap { $0["text"].string }.joined() }
}
