collection @products, root: false, object_root: false

attributes :platform, :price

child :purchases do
  attributes :price, :modified, :version
end