const express = require('express');
const products = require('./data/products.json');
const app = express();
const port = process.env.PORT || 3000;

app.get('/', (req, res) => {
  const productCards = products
    .map(
      (product) => `
      <div style="border:1px solid #ddd; padding: 16px; margin: 8px; border-radius: 8px; width: 280px;">
        <h2>${product.name}</h2>
        <p>Price: $${product.price}</p>
        <p>${product.description}</p>
      </div>`
    )
    .join('');

  res.send(`
    <html>
      <head>
        <title>E-Commerce Store</title>
        <style>
          body { font-family: Arial, sans-serif; background: #f8f8f8; padding: 20px; }
          .grid { display: flex; flex-wrap: wrap; gap: 16px; }
        </style>
      </head>
      <body>
        <h1>E-Commerce Store</h1>
        <div class="grid">${productCards}</div>
      </body>
    </html>
  `);
});

app.get('/api/products', (req, res) => {
  res.json(products);
});

app.listen(port, () => {
  console.log(`E-Commerce app listening on port ${port}`);
});
