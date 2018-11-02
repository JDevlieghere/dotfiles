function gscp -d "Create patch for head and scp it"
  git show HEAD -U999999 > /tmp/head.patch
  scp /tmp/patch "$argv":/tmp/head.patch
end
