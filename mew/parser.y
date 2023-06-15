start: document

document: block

block: sequence
      | mapping

sequence: SEQUENCE_START items SEQUENCE_END

items: item
     | items item

item: block
    | SCALAR

mapping: MAPPING_START pairs MAPPING_END

pairs: pair
     | pairs pair

pair: SCALAR COLON block

