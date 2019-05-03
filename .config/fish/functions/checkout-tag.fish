function checkout-tag -d "Checkout a tag"
  git fetch --tags
  git checkout "$argv"
end
