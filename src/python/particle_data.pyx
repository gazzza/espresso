#from espresso.utils cimport ERROR 
cimport numpy as np
import numpy as np
cimport utils
from utils cimport *
include "myconfig.pxi"


cdef class ParticleHandle:
  def __cinit__(self, _id):
#    utils.init_intlist(self.particleData.el)
    utils.init_intlist(&(self.particleData.bl))
    self.id=_id

  cdef int update_particle_data(self) except -1:
#    utils.realloc_intlist(self.particleData.el, 0)
    utils.realloc_intlist(&(self.particleData.bl), 0)
      
    if get_particle_data(self.id, &self.particleData):
      raise Exception("Error updating particle data")
    else: 
      return 0


  # The individual attributes of a particle are implemented as properties.

# Particle Type

  property type:
    """Particle type"""
    def __set__(self, _type):
      if isinstance(_type, int) and _type >= 0:  
        if set_particle_type(self.id, _type) == 1:
          raise Exception("set particle position first")
      else:
        raise ValueError("type must be an integer >= 0")
    def __get__(self):
      self.update_particle_data()
      return self.particleData.p.type

  property mass:
    """Particle mass"""
    def __set__(self, _mass):
      checkTypeOrExcept(_mass,1,float,"Mass has to be 1 floats")
      if set_particle_mass(self.id, _mass) == 1:
        raise Exception("set particle position first")
    
    def __get__(self):
      self.update_particle_data()
      return self.particleData.p.mass




# Position

  property pos:
    """Particle position (not folded into periodic box)"""
    def __set__(self, _pos):
      cdef double mypos[3]
      checkTypeOrExcept(_pos, 3,float,"Postion must be 3 floats")
      for i in range(3): mypos[i]=_pos[i]
      if place_particle(self.id, mypos) == -1:
        raise Exception("particle could not be set")

    def __get__(self):
      self.update_particle_data()
      return np.array([self.particleData.r.p[0],\
                       self.particleData.r.p[1],\
                       self.particleData.r.p[2]])


# Velocity
  property v:
    """Particle velocity""" 
    def __set__(self, _v):
      cdef double myv[3]
      checkTypeOrExcept(_v,3,float,"Velocity has to be floats")
      for i in range(3):
          myv[i]=_v[i]
      if set_particle_v(self.id, myv) == 1:
        raise Exception("set particle position first")
    def __get__(self):
      self.update_particle_data()
      return np.array([ self.particleData.m.v[0],\
                        self.particleData.m.v[1],\
                        self.particleData.m.v[2]])

# Force
  property f:
    """Particle force"""
    def __set__(self, _f):
      cdef double myf[3]
      checkTypeOrExcept(_f,3,float, "Force has to be floats")
      for i in range(3):
          myf[i]=_f[i]
      if set_particle_f(self.id, myf) == 1:
        raise Exception("set particle position first")
    def __get__(self):
      self.update_particle_data()
      return np.array([ self.particleData.f.f[0],\
                        self.particleData.f.f[1],\
                        self.particleData.f.f[2]])
  IF ROTATION ==1:
# Omega (angular velocity) lab frame
    property omega_lab:
      """Angular velocity in lab frame""" 
      def __set__(self, _o):
        cdef double myo[3]
        checkTypeOrExcept(_o,3,float,"Omega_lab has to be 3 floats")
        for i in range(3):
            myo[i]=_o[i]
        if set_particle_omega_lab(self.id, myo) == 1:
          raise Exception("set particle position first")

      def __get__(self):
        self.update_particle_data()
        cdef double o[3]
        convert_omega_body_to_space(self.particleData, o);
        return np.array([ o[0], o[1],o[2]])

# Omega (angular velocity) body frame
    property omega_body:
      """Angular velocity in body frame""" 
      def __set__(self, _o):
        cdef double myo[3]
        checkTypeOrExcept(_o,3,float,"Omega_body has to be 3 floats")
        for i in range(3):
            myo[i]=_o[i]
        if set_particle_omega_body(self.id, myo) == 1:
          raise Exception("set particle position first")
      def __get__(self):
        self.update_particle_data()
        return np.array([ self.particleData.m.omega_body[0],\
                          self.particleData.m.omega_body[1],\
                          self.particleData.m.omega_body[2]])
  
  
  
  
# Torque in lab frame
    property torque_lab:
      """Torque in lab frame""" 
      def __set__(self, _t):
        cdef double myt[3]
        checkTypeOrExcept(_t,3,float,"Torque has to be 3 floats")
        for i in range(3):
            myt[i]=_t[i]
        if set_particle_torque_lab(self.id, myt) == 1:
          raise Exception("set particle position first")
      def __get__(self):
        self.update_particle_data()
        return np.array([ self.particleData.f.torque[0],\
                          self.particleData.f.torque[1],\
                          self.particleData.f.torque[2]])
  
# Quaternion
    property quat:
      """Quaternions""" 
      def __set__(self, _q):
        cdef double myq[4]
        checkTypeOrExcept(_q,4,float,"Quaternions has to be 4 floats")
        for i in range(4):
            myq[i]=_q[i]
        if set_particle_quat(self.id, myq) == 1:
          raise Exception("set particle position first")
      def __get__(self):
        self.update_particle_data()
        return np.array([ self.particleData.r.quat[0],\
                          self.particleData.r.quat[1],\
                          self.particleData.r.quat[2],\
                          self.particleData.r.quat[3]])
  
  
# Force
# Charge
  IF ELECTROSTATICS == 1:
    property q:
      """particle charge"""
      def __set__(self, _q):
        cdef double myq
        checkTypeOrExcept(_q,1,float, "Charge has to be floats")
        myq=_q
        if set_particle_q(self.id, myq) == 1:
          raise Exception("set particle position first")
      def __get__(self):
        self.update_particle_data()
        return self.particleData.p.q

  def delete(self):
    """Delete the particle"""
    if remove_particle(self.id):
      raise Exception("Could not delete particle")
    del self


  IF VIRTUAL_SITES ==1:
# virtual flag

    property virtual:
      """virtual flag"""
      def __set__(self, _v):
        if isinstance(_v, int):  
          if set_particle_virtual(self.id, _v) == 1:
            raise Exception("set particle position first")
        else:
          raise ValueError("virtual must be an integer >= 0")
      def __get__(self):
        self.update_particle_data()
        return self.particleData.p.virtual


# Virtual sites relative parameters
    property vs_relative:
      """virtual sites relative parameters"""
      def __set__(self, _relto,_dist):
        if isinstance(_relto, int) and isinstance(_dist,float):  
          if set_particle_vs_relative(self.id, _relto,_dist) == 1:
            raise Exception("set particle position first")
        else:
          raise ValueError("vs_relative takes one int and one float as parameters.")
    def __get__(self):
      self.update_particle_data()
      return (self.particleData.p.vs_relative_to,self.particleData.p.vs_relative_distance)

# vs_auto_relate_to
    def vs_auto_relate_to(self,_relto):
      """Setup this particle as virtual site relative to the particle with the given id"""
      if isinstance(_relto,int):
          if vs_relate_to(self.id,_relto):
            raise Exception("Vs_relative setup failed.")
      else:
            raise ValueError("Argument of vs_auto_relate_to has to be of type int")



cdef class particleList:
  """Provides access to the particles via [i], where i is the particle id. Returns a ParticleHandle object """
  def __getitem__(self, key):
    return ParticleHandle(key)


