import Foundation

// MARK: - Opaque context wrapper

private final class PluginHandle {
    let context = PluginContext()
}

// MARK: - C ABI function implementations

private func pluginInit() -> UnsafeMutableRawPointer? {
    let handle = PluginHandle()
    return Unmanaged.passRetained(handle).toOpaque()
}

private func pluginDestroy(_ rawCtx: UnsafeMutableRawPointer?) {
    guard let rawCtx else { return }
    Unmanaged<PluginHandle>.fromOpaque(rawCtx).release()
}

private func pluginGetManifest(_ rawCtx: UnsafeMutableRawPointer?) -> UnsafeMutablePointer<CChar>? {
    return strdup(Manifest.json)
}

private func pluginInvoke(
    _ rawCtx: UnsafeMutableRawPointer?,
    _ type: UnsafePointer<CChar>?,
    _ id: UnsafePointer<CChar>?,
    _ payload: UnsafePointer<CChar>?
) -> UnsafeMutablePointer<CChar>? {
    guard let rawCtx else {
        return strdup("{\"error\": \"Plugin not initialized\"}")
    }
    let handle = Unmanaged<PluginHandle>.fromOpaque(rawCtx).takeUnretainedValue()
    let typeStr = type.map { String(cString: $0) } ?? ""
    let idStr = id.map { String(cString: $0) } ?? ""
    let payloadStr = payload.map { String(cString: $0) } ?? "{}"

    let result = Router.invoke(ctx: handle.context, type: typeStr, id: idStr, payload: payloadStr)
    return strdup(result)
}

private func pluginFreeString(_ s: UnsafeMutablePointer<CChar>?) {
    free(s)
}

// MARK: - Static API table

private var api = (
    pluginFreeString,
    pluginInit,
    pluginDestroy,
    pluginGetManifest,
    pluginInvoke
)

// MARK: - Exported entry point

@_cdecl("osaurus_plugin_entry")
public func osaurusPluginEntry() -> UnsafeRawPointer {
    return withUnsafePointer(to: &api) { ptr in
        return UnsafeRawPointer(ptr)
    }
}
