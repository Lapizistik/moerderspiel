# coding: utf-8

# wir zählen die disjunkten Kreise
def per_count(n)
  # oBdA: 1 an erster Stelle
  1 + (2..n).to_a.permutation.count { |a|
    (a.first != 2) && (a.last != n) &&
      a.each_cons(2).all? { |u,v| u+1 != v }
  }
end
  
def per_ratio(n)
  per_count(n).to_r / (1..n-1).inject(:*)
end
