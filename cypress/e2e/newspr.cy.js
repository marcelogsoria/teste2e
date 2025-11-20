describe('Test NewsPR - Primera Noticia', () => {
  it('debe hacer click en la primera noticia y verificar que se cargue el título', () => {
    // Visitar la página principal de NewsPR
    cy.visit('/')

    // Esperar a que la página cargue completamente
    cy.get('body').should('be.visible')

    // Buscar y hacer click en la primera noticia
    // Intentamos varios selectores comunes para encontrar la primera noticia
    cy.get('article:first, .news-item:first, .article:first, a[href*="/news/"]:first, a[href*="/article/"]:first, .card:first a, .post:first a')
      .first()
      .should('be.visible')
      .click({ force: true })

    // Esperar a que se cargue la página de la noticia
    cy.url().should('not.equal', Cypress.config('baseUrl') + '/')

    // Verificar que el título de la noticia tenga texto y sea visible
    cy.get('h1, .article-title, .post-title, .news-title, [class*="title"]')
      .first()
      .should('be.visible')
      .should('not.be.empty')
      .invoke('text')
      .should('have.length.greaterThan', 0)

    // Log adicional para debugging
    cy.get('h1, .article-title, .post-title, .news-title, [class*="title"]')
      .first()
      .then(($title) => {
        cy.log('Título encontrado: ' + $title.text())
      })
  })
})

