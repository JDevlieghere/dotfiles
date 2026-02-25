function checkout-pr -d "Checkout GitHub PR"
  git fetch origin main
  git fetch origin pull/$argv/head:review-$argv
  git switch review-$argv
end
