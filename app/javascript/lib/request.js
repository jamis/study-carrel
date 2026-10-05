// Small helpers shared by the controllers that talk to the server.

export const csrfToken = () => document.querySelector("meta[name=csrf-token]")?.content

// Route helpers encode "{id}" as "%7Bid%7D"; fill in either form.
export const fillId = (template, id) => template.replace(/%7Bid%7D|\{id\}/, id)
