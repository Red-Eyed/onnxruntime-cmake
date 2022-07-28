# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.

file(GLOB onnxruntime_session_srcs CONFIGURE_DEPENDS
    "${ONNXRUNTIME_INCLUDE_DIR}/core/session/*.h"
    "${ONNXRUNTIME_ROOT}/core/session/*.h"
    "${ONNXRUNTIME_ROOT}/core/session/*.cc"
    )

if (onnxruntime_ENABLE_TRAINING_ON_DEVICE)
  file(GLOB_RECURSE on_device_training_api_srcs CONFIGURE_DEPENDS
    "${ORTTRAINING_SOURCE_DIR}/training_api/*.cc"
  )

  list(APPEND onnxruntime_session_srcs ${on_device_training_api_srcs})
endif()


if (onnxruntime_MINIMAL_BUILD)
  set(onnxruntime_session_src_exclude
    "${ONNXRUNTIME_ROOT}/core/session/provider_bridge_ort.cc"
  )

  list(REMOVE_ITEM onnxruntime_session_srcs ${onnxruntime_session_src_exclude})
endif()

source_group(TREE ${REPO_ROOT} FILES ${onnxruntime_session_srcs})

onnxruntime_add_static_library(onnxruntime_session ${onnxruntime_session_srcs})
set(onnxruntime_session_public_header
  "${ONNXRUNTIME_INCLUDE_DIR}/core/session/onnxruntime_session_options_config_keys.h"
  "${ONNXRUNTIME_INCLUDE_DIR}/core/session/onnxruntime_c_api.h"
  "${ONNXRUNTIME_INCLUDE_DIR}/core/session/onnxruntime_cxx_api.h"
  "${ONNXRUNTIME_INCLUDE_DIR}/core/session/onnxruntime_cxx_inline.h"
  "${ONNXRUNTIME_INCLUDE_DIR}/core/session/onnxruntime_run_options_config_keys.h"
)
install(FILES ${onnxruntime_session_public_header}  DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/onnxruntime)
onnxruntime_add_include_to_target(onnxruntime_session onnxruntime_common onnxruntime_framework onnx onnx_proto ${PROTOBUF_LIB} flatbuffers)
if(onnxruntime_ENABLE_INSTRUMENT)
  target_compile_definitions(onnxruntime_session PUBLIC ONNXRUNTIME_ENABLE_INSTRUMENT)
endif()

if(NOT MSVC)
  set_source_files_properties(${ONNXRUNTIME_ROOT}/core/session/environment.cc PROPERTIES COMPILE_FLAGS  "-Wno-parentheses")
endif()
target_include_directories(onnxruntime_session PRIVATE ${ONNXRUNTIME_ROOT} ${eigen_INCLUDE_DIRS})
target_link_libraries(onnxruntime_session PRIVATE nlohmann_json::nlohmann_json)
if (onnxruntime_USE_EXTENSIONS)
  target_link_libraries(onnxruntime_session PRIVATE onnxruntime_extensions)
endif()
add_dependencies(onnxruntime_session ${onnxruntime_EXTERNAL_DEPENDENCIES})
set_target_properties(onnxruntime_session PROPERTIES FOLDER "ONNXRuntime")
if (onnxruntime_USE_CUDA)
  target_include_directories(onnxruntime_session PRIVATE ${onnxruntime_CUDNN_HOME}/include ${CMAKE_CUDA_TOOLKIT_INCLUDE_DIRECTORIES})
endif()
if (onnxruntime_USE_ROCM)
  target_compile_options(onnxruntime_session PRIVATE -Wno-sign-compare -D__HIP_PLATFORM_HCC__=1)
  target_include_directories(onnxruntime_session PRIVATE ${onnxruntime_ROCM_HOME}/hipfft/include ${onnxruntime_ROCM_HOME}/include ${onnxruntime_ROCM_HOME}/hipcub/include ${onnxruntime_ROCM_HOME}/hiprand/include ${onnxruntime_ROCM_HOME}/rocrand/include)
# ROCM provider sources are generated, need to add include directory for generated headers
  target_include_directories(onnxruntime_session PRIVATE ${CMAKE_CURRENT_BINARY_DIR}/amdgpu/onnxruntime ${CMAKE_CURRENT_BINARY_DIR}/amdgpu/orttraining)
endif()
if (onnxruntime_ENABLE_TRAINING OR onnxruntime_ENABLE_TRAINING_OPS)
  target_include_directories(onnxruntime_session PRIVATE ${ORTTRAINING_ROOT})
endif()

if (onnxruntime_ENABLE_TRAINING_TORCH_INTEROP)
  onnxruntime_add_include_to_target(onnxruntime_session Python::Module)
endif()

if (NOT onnxruntime_BUILD_SHARED_LIB)
    #TODO: Cannot set part of ORT targets as it depends on nlohmann_json which is not part of any export set,
    # can be fixed if we use installed target nlohmann_json instead of submodule
    install(TARGETS onnxruntime_session
            # EXPORT ${PROJECT_NAME}Targets
            ARCHIVE   DESTINATION ${CMAKE_INSTALL_LIBDIR}
            LIBRARY   DESTINATION ${CMAKE_INSTALL_LIBDIR}
            RUNTIME   DESTINATION ${CMAKE_INSTALL_BINDIR}
            FRAMEWORK DESTINATION ${CMAKE_INSTALL_BINDIR})
endif()
