import ManagedSettings

extension ManagedSettingsStore {
    func filterDomains() -> Set<WebDomain> {
        if case let .specific(domains)? = webContent.blockedByFilter {
            return domains
        }
        return []
    }

    func replaceFilterDomains(_ domains: [String]) {
        writeFilter(WebFilter.webDomains(from: domains))
    }

    private func writeFilter(_ domains: Set<WebDomain>) {
        webContent.blockedByFilter = WebFilter.policy(for: domains)
    }
}

enum WebFilter {
    static func webDomains(from domains: [String]) -> Set<WebDomain> {
        Set(domains.compactMap(DomainNormalizer.normalize).map { WebDomain(domain: $0) })
    }

    static func policy(for domains: Set<WebDomain>) -> WebContentSettings.FilterPolicy? {
        domains.isEmpty ? nil : .specific(domains)
    }
}
