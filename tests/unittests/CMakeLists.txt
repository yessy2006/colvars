add_executable(colvarvalue_unit3vector colvarvalue_unit3vector.cpp)
target_link_libraries(colvarvalue_unit3vector PRIVATE colvars)
target_include_directories(colvarvalue_unit3vector PRIVATE ${COLVARS_SOURCE_DIR}/src)

add_executable(file_io file_io.cpp)
target_link_libraries(file_io PRIVATE colvars)
target_include_directories(file_io PRIVATE ${COLVARS_SOURCE_DIR}/src)
